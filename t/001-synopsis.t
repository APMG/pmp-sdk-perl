#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 59;
use Data::Dump qw( dump );

use_ok('Net::PMP::Client');
use_ok('Net::PMP::CollectionDoc');

SKIP: {
    if ( !$ENV{PMP_CLIENT_ID} or !$ENV{PMP_CLIENT_SECRET} ) {
        skip "set PMP_CLIENT_ID and PMP_CLIENT_SECRET to test API", 57;
    }

    # basic authn

    ok( my $client = Net::PMP::Client->new(
            host => ( $ENV{PMP_CLIENT_HOST} || 'https://api-sandbox.pmp.io' ),
            id => $ENV{PMP_CLIENT_ID},
            secret => $ENV{PMP_CLIENT_SECRET},
            debug  => $ENV{PMP_CLIENT_DEBUG},
        ),
        "new client"
    );

    ok( my $token = $client->get_token(), "get token" );

    cmp_ok( $token->expires_in, '>=', 10, 'token expires_in >= 10' );

    ok( $client->revoke_token(), "revoke_token" );

    # introspection

    ok( my $doc = $client->get_doc(), "client->get_doc()" );

    ok( my $query_rel_types = $doc->get_links('query')->query_rel_types(),
        "get query_rel_types for base endpoint" );

    #diag( dump($query_rel_types) );

    is_deeply(
        $query_rel_types,
        {   "urn:pmp:hreftpl:docs"     => "Access documents",
            "urn:pmp:hreftpl:profiles" => "Access profiles",
            "urn:pmp:hreftpl:schemas"  => "Access schemas",
            "urn:pmp:query:docs"       => "Query for documents",
            "urn:pmp:query:groups"     => "Query for groups",
            "urn:pmp:query:guids"      => "Generate guids",
            "urn:pmp:query:users"      => "Query for users",
        },
        "got expected rel types"
    );

    ok( my $query_options = $doc->query('urn:pmp:query:docs')->options(),
        "query->options" );

    #diag( dump $query_options );

    is_deeply(
        $query_options,
        {   author =>
                "https://github.com/publicmediaplatform/pmpdocs/wiki/Content-Retrieval",
            collection =>
                "https://github.com/publicmediaplatform/pmpdocs/wiki/Content-Retrieval",
            distributor =>
                "https://github.com/publicmediaplatform/pmpdocs/wiki/Content-Retrieval",
            distributorgroup =>
                "https://github.com/publicmediaplatform/pmpdocs/wiki/Content-Retrieval",
            enddate =>
                "https://github.com/publicmediaplatform/pmpdocs/wiki/Content-Retrieval",
            has =>
                "https://github.com/publicmediaplatform/pmpdocs/wiki/Content-Retrieval",
            language =>
                "https://github.com/publicmediaplatform/pmpdocs/wiki/Content-Retrieval",
            limit =>
                "https://github.com/publicmediaplatform/pmpdocs/wiki/Content-Retrieval",
            offset =>
                "https://github.com/publicmediaplatform/pmpdocs/wiki/Content-Retrieval",
            profile =>
                "https://github.com/publicmediaplatform/pmpdocs/wiki/Content-Retrieval",
            searchsort =>
                "https://github.com/publicmediaplatform/pmpdocs/wiki/Content-Retrieval",
            startdate =>
                "https://github.com/publicmediaplatform/pmpdocs/wiki/Content-Retrieval",
            tag =>
                "https://github.com/publicmediaplatform/pmpdocs/wiki/Content-Retrieval",
            text =>
                "https://github.com/publicmediaplatform/pmpdocs/wiki/Content-Retrieval",
        },
        "got expected query options"
    );

    ############################################################################
    # search sample content

    ok( my $search_results
            = $client->search(
            { tag => 'samplecontent', profile => 'story' } ),
        "submit search"
    );
    ok( my $results = $search_results->get_items(),
        "get search_results->get_items()"
    );
    cmp_ok( $results->total, '>=', 10, ">= 10 results" );
    diag( 'total: ' . $results->total );
    while ( my $r = $results->next ) {

        #diag( dump $r );
        diag(
            sprintf( '%s: %s [%s]',
                $results->count, $r->get_uri, $r->get_title, )
        );
        ok( $r->get_uri,     "get uri" );
        ok( $r->get_title,   "get title" );
        ok( $r->get_profile, "get profile" );
    }

    ############################################################################
    # CRUD

    ok( my $sample_doc = Net::PMP::CollectionDoc->new(
            version    => '1.0',
            attributes => {
                tags  => [qw( pmp-sdk-testcontent )],
                title => 'i am a test document',

                #guid  => '5890510b-f237-3714-9f51-36ceafd8bbb7',
            },
            links => {
                profile => [ { href => $client->host . '/profiles/story' } ]
            },
        ),
        "create new sample doc"
    );

    # Create
    ok( $client->save($sample_doc), "save sample doc" );
    is( $client->last_response->code, 202, "save response was 202" );
    ok( $sample_doc->get_uri(),  "saved sample doc has uri" );
    ok( $sample_doc->get_guid(), "saved sample doc has guid" );

    sleep(3);    # since create is 202 ...

    # Read
    ok( $search_results = $client->get_doc( $sample_doc->get_uri() ),
        "search for sample doc" );
    is( $client->last_response->code, 200, 'search response was 200' );
    if ( $client->last_response->code == 200 ) {
        is( $search_results->get_guid(),
            $sample_doc->get_guid(),
            "search results guid == sample doc guid"
        );
    }
    else {
        pass("search latency too great -- skipping results test");
    }

    # Update
    $sample_doc->attributes->{title} = 'i am a test document, redux';
    ok( $client->save($sample_doc), "update title" );
    is( $client->last_response->code, 202, "save response was 202" );
    sleep(3);    # since update is 202
    ok( $search_results = $client->get_doc( $sample_doc->get_uri ),
        "re-fetch sample doc" );
    is( $search_results->get_title,
        $sample_doc->get_title, "search results title == sample doc title" );

    # Delete
    ok( $client->delete($sample_doc), "delete sample doc" );
    is( $client->last_response->code, 204, "delete response was 204" );
    sleep(3);    # since delete is 204 but really maybe should be 202?
    ok( !$client->get_doc( $sample_doc->get_uri ),
        "get_doc() for sample now empty"
    );
}
