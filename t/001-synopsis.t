#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 9;
use Data::Dump qw( dump );

use_ok('Net::PMP::Client');
use_ok('Net::PMP::CollectionDoc');

SKIP: {
    if ( !$ENV{PMP_CLIENT_ID} or !$ENV{PMP_CLIENT_SECRET} ) {
        skip "set PMP_CLIENT_ID and PMP_CLIENT_SECRET to test API", 7;
    }

    ok( my $client = Net::PMP::Client->new(
            host   => 'https://api-sandbox.pmp.io',
            id     => $ENV{PMP_CLIENT_ID},
            secret => $ENV{PMP_CLIENT_SECRET},
            debug  => $ENV{PMP_CLIENT_DEBUG},
        ),
        "new client"
    );

    ok( my $token = $client->get_token(), "get token" );

    cmp_ok( $token->expires_in, '>=', 10, 'token expires_in >= 10' );

    ok( $client->revoke_token(), "revoke_token" );

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
            "urn:pmp:query:files"      => "Upload media files",
            "urn:pmp:query:groups"     => "Query for groups",
            "urn:pmp:query:guids"      => "Generate guids",
            "urn:pmp:query:users"      => "Query for users",
        },
        "got expected rel types"
    );

}
