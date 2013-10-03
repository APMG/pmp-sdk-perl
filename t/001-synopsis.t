#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 4;
use Data::Dump qw( dump );

use_ok('Net::PMP::Client');

SKIP: {
    if ( !$ENV{PMP_CLIENT_ID} or !$ENV{PMP_CLIENT_SECRET} ) {
        skip "set PMP_CLIENT_ID and PMP_CLIENT_SECRET to test API", 3;
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
}
