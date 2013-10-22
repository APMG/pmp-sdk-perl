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

    # create client
    ok( my $client = Net::PMP::Client->new(
            host => ( $ENV{PMP_CLIENT_HOST} || 'https://api-sandbox.pmp.io' ),
            id => $ENV{PMP_CLIENT_ID},
            secret => $ENV{PMP_CLIENT_SECRET},
            debug  => $ENV{PMP_CLIENT_DEBUG},
        ),
        "new client"
    );

    # clean up any previous false runs
    for my $profile (qw( story organization group )) {
        my $authz_test = $client->search(
            {   profile => $profile,
                text    => 'pmp-sdk-perl',
                limit   => 100,
            }
        );
        if ($authz_test) {
            my $prev_test = $authz_test->get_items();
            while ( my $item = $prev_test->next ) {
                diag( "cleaning up " . $item->get_uri );
                $client->delete($item);
            }
        }
    }

    # create 3 orgs
    my $org1_pass = Net::PMP::CollectionDoc->create_guid();
    my $org2_pass = Net::PMP::CollectionDoc->create_guid();
    my $org3_pass = Net::PMP::CollectionDoc->create_guid();
    ok( my $org1 = Net::PMP::CollectionDoc->new(
            version    => $client->get_doc->version,
            attributes => {
                tags  => [qw( pmp-sdk-perl-test-authz )],
                title => 'pmp-sdk-perl test org1',
                auth  => {
                    user     => 'pmp-sdk-perl-org1',
                    password => $org1_pass,
                },
            },
            links => {
                profile =>
                    [ { href => $client->uri_for_profile('organization') } ]
            },
        ),
        "create org1"
    );
    ok( $client->save($org1), "save org1" );
    ok( my $org2 = Net::PMP::CollectionDoc->new(
            version    => $client->get_doc->version,
            attributes => {
                tags  => [qw( pmp-sdk-perl-test-authz )],
                title => 'pmp-sdk-perl test org2',
                auth  => {
                    user     => 'pmp-sdk-perl-org2',
                    password => $org2_pass,
                },
            },
            links => {
                profile =>
                    [ { href => $client->uri_for_profile('organization') } ]
            },
        ),
        "create org2"
    );
    ok( $client->save($org2), "save org2" );
    ok( my $org3 = Net::PMP::CollectionDoc->new(
            version    => $client->get_doc->version,
            attributes => {
                tags  => [qw( pmp-sdk-perl-test-authz )],
                title => 'pmp-sdk-perl test org3',
                auth  => {
                    user     => 'pmp-sdk-perl-org3',
                    password => $org3_pass,
                },
            },
            links => {
                profile =>
                    [ { href => $client->uri_for_profile('organization') } ]
            },
        ),
        "create org3"
    );
    ok( $client->save($org3), "save org3" );

    # create group
    ok( my $group = Net::PMP::CollectionDoc->new(
            version    => $client->get_doc->version,
            attributes => {
                title => 'pmp-sdk-perl permission group',
                tags  => [qw( pmp-sdk-perl-test-authz )],
            },
            links => {
                profile => [ { href => $client->uri_for_profile('group') } ]
            },
        ),
        "create group"
    );
    ok( $group->add_item($org1), "add org1 to group" );
    ok( $group->add_item($org2), "add org2 to group" );
    ok( $client->save($group),   "save group" );

    # add fixture docs
    ok( my $sample_doc1 = Net::PMP::CollectionDoc->new(
            version    => $client->get_doc->version,
            attributes => {
                tags  => [qw( pmp-sdk-perl-test-authz )],
                title => 'i am a test document one',
            },
            links => {
                profile => [ { href => $client->uri_for_profile('story') } ],
                permissions =>
                    [ { href => $group->get_uri(), operation => 'read', }, ],
            },
        ),
        "create new sample doc1"
    );
    ok( $client->save($sample_doc1), "save sample doc1" );

    ok( my $sample_doc2 = Net::PMP::CollectionDoc->new(
            version    => $client->get_doc->version,
            attributes => {
                tags  => [qw( pmp-sdk-perl-test-authz )],
                title => 'i am a test document two',
            },
            links => {
                profile => [ { href => $client->uri_for_profile('story') } ],
                permissions => [
                    {   href      => $group->get_uri(),
                        operation => 'read',
                        blacklist => \1,
                    },
                ],
            },
        ),
        "create new sample doc2"
    );
    ok( $client->save($sample_doc2), "save sample doc2" );

    ok( my $sample_doc3 = Net::PMP::CollectionDoc->new(
            version    => $client->get_doc->version,
            attributes => {
                tags  => [qw( pmp-sdk-perl-test-authz )],
                title => 'i am a test document three',
            },
            links => {
                profile => [ { href => $client->uri_for_profile('story') } ]
            },
        ),
        "create new sample doc3"
    );
    ok( $client->save($sample_doc3), "save sample doc3" );

    # fixtures all in place
    # now create credentials and client for orgs
    ok( my $org1_creds = $client->create_credentials(
            username => $org1->attributes->{auth}->{user},
            password => $org1_pass,
        ),
        "create org1 credentials"
    );
    ok( my $org2_creds = $client->create_credentials(
            username => $org2->attributes->{auth}->{user},
            password => $org2_pass,
        ),
        "create org2 credentials"
    );
    ok( my $org3_creds = $client->create_credentials(
            username => $org3->attributes->{auth}->{user},
            password => $org3_pass,
        ),
        "create org3 credentials"
    );
    ok( my $org1_client = Net::PMP::Client->new(
            id     => $org1_creds->client_id,
            secret => $org1_creds->client_secret,
            debug  => $client->debug,
        ),
        "create org1 client"
    );
    ok( my $org2_client = Net::PMP::Client->new(
            id     => $org2_creds->client_id,
            secret => $org2_creds->client_secret,
            debug  => $client->debug,
        ),
        "create org2 client"
    );
    ok( my $org3_client = Net::PMP::Client->new(
            id     => $org3_creds->client_id,
            secret => $org3_creds->client_secret,
            debug  => $client->debug,
        ),
        "create org3 client"
    );

    # org1 should see all docs
    # org2 should see doc1 and doc3
    # org3 should see only doc3
    ok( my $org1_res
            = $org1_client->search( { tags => 'pmp-sdk-testcontent' } ),
        "org1 search"
    );
    ok( my $org2_res
            = $org2_client->search( { tags => 'pmp-sdk-testcontent' } ),
        "org2 search"
    );
    ok( my $org3_res
            = $org2_client->search( { tags => 'pmp-sdk-testcontent' } ),
        "org3 search"
    );
    is( $org1_res->has_items, 3, "org1 has 3 items" );
    is( $org2_res->has_items, 2, "org2 has 2 items" );
    is( $org3_res->has_items, 1, "org3 has 1 item" );

    diag( dump $org1_res );
    diag( dump $org2_res );
    diag( dump $org3_res );

}

