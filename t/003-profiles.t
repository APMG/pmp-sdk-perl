#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 8;
use Data::Dump qw( dump );

use_ok('Net::PMP::Profile');
use_ok('Net::PMP::CollectionDoc');

ok( my $profile_doc = Net::PMP::Profile->new(
        title     => 'I am A Title',
        published => '2013-12-03T12:34:56.789Z',
        valid     => {
            from => "2013-04-11T13:21:31.598Z",
            to   => "3013-04-11T13:21:31.598Z",
        },
        byline      => 'By: John Writer and Nancy Author',
        description => 'This is a summary of the document.',
        tags        => [qw( foo bar baz )],
        hreflang    => 'en',
        author      => [qw( http://api.pmp.io/user/some-guid )],
        copyright   => [qw( http://americanpublicmedia.org/ )],
        distributor => [qw( http://api.pmp.io/organization/different-guid )],
    ),
    "synopsis constructor"
);

# validation
eval {
    my $bad_date = Net::PMP::Profile->new(
        title     => 'test bad date',
        published => 'no way date',
    );
};

like( $@, qr/Invalid date format/i, "bad date constructor" );

eval {
    my $bad_locale = Net::PMP::Profile->new(
        title    => 'bad locale',
        hreflang => 'ENGLISH',
    );
};

like( $@, qr/not a valid ISO639-1 value/, "bad hreflang constructor" );

eval {
    my $bad_valid = Net::PMP::Profile->new(
        title => 'bad valid date',
        valid => { from => 'now', to => 'then' },
    );
};

like( $@, qr/Invalid date format/i, "bad valid date" );

eval {
    my $bad_valid = Net::PMP::Profile->new(
        title => 'bad valid date missing key',
        valid => { to => 'then' },
    );
};

like( $@, qr/must contain/i, "bad valid date missing key" );

eval {
    my $bad_author = Net::PMP::Profile->new(
        title  => 'bad author',
        author => [qw( /foo/bar )],
    );
};

like( $@, qr/does not appear to be an array of hrefs/, "bad author href" );
