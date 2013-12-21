#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 30;
use Data::Dump qw( dump );

use_ok('Net::PMP::Profile');
use_ok('Net::PMP::Profile::Story');
use_ok('Net::PMP::Profile::Media');
use_ok('Net::PMP::Profile::Audio');
use_ok('Net::PMP::Profile::Video');
use_ok('Net::PMP::Profile::Image');
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
        permission  => [qw( http://api.pmp.io/docs/some-group-guid )],
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

like( $@, qr/not a valid href/, "bad author href" );

ok( my $coll_doc = $profile_doc->as_doc(), "profile->as_doc" );
ok( $coll_doc->isa('Net::PMP::CollectionDoc'), "coll_doc isa CollectionDoc" );

#diag( dump $coll_doc );
#diag( $profile_doc->published );

is_deeply(
    $coll_doc->attributes,
    {   title       => $profile_doc->title,
        published   => $profile_doc->published,
        valid       => $profile_doc->valid,
        byline      => $profile_doc->byline,
        description => $profile_doc->description,
        tags        => $profile_doc->tags,
        hreflang    => $profile_doc->hreflang,
    },
    "coll_doc attributes"
);

is_deeply(
    $coll_doc->as_hash->{links},
    {   author    => [ { href => "http://api.pmp.io/user/some-guid" } ],
        copyright => [ { href => "http://americanpublicmedia.org/" } ],
        distributor =>
            [ { href => "http://api.pmp.io/organization/different-guid" } ],
        permission => [
            {   href      => "http://api.pmp.io/docs/some-group-guid",
                operation => "read",
            },
        ],
        profile => [
            {   href  => "https://api.pmp.io/profiles/base",
                title => "Net::PMP::Profile",
            },
        ],
    },
    "collection links"
);

#diag( dump( $coll_doc->as_hash ) );
#diag( $coll_doc->as_json );

# timezone

ok( my $tzdoc = Net::PMP::Profile->new(
        title     => 'i am a PST',
        published => '1972-03-29 06:08:00 -0700',
    ),
    "new Doc in PST"
);
is( $tzdoc->as_doc->attributes->{published},
    '1972-03-29T13:08:00.000Z', "published date converted to UTC" );

# media
ok( my $audio = Net::PMP::Profile::Audio->new(
        title       => 'i am a piece of audio',
        description => 'hear me',
        enclosure   => [
            { href => 'http://mpr.org/some/audio.mp3', type => 'audio/mpeg' },
        ]
    ),
    "audio constructor"
);

ok( my $audio_doc = $audio->as_doc(), "audio->as_doc" );

#diag( dump $audio_doc );
is_deeply(
    $audio_doc->links,
    {   enclosure => [
            {   href => 'http://mpr.org/some/audio.mp3',
                type => 'audio/mpeg',
            }
        ],
        profile => [
            {   href  => "https://api.pmp.io/profiles/audio",
                title => 'Net::PMP::Profile::Audio',
            },
        ],
    },
    "Media enclosure recognized as link"
);

eval {
    my $audio = Net::PMP::Profile::Audio->new(
        title     => 'bad audio enclosure',
        enclosure => 'foo'
    );
};

like(
    $@,
    qr/Validation failed for 'Net::PMP::Type::MediaEnclosures'/,
    "bad audio enclosure - string"
);

ok( my $audio_single_enclosure = Net::PMP::Profile::Audio->new(
        title => 'bad audio enclosure',
        enclosure =>
            { href => 'http://mpr.org/some/audio.mp3', type => 'audio/mpeg' },
    ),
    "audio constructor with single enclosure"
);

eval {
    my $audio = Net::PMP::Profile::Audio->new(
        title => 'bad audio enclosure',
        enclosure =>
            [ { href => 'http://mpr.org/some/audio.mp3', type => 'foo' }, ],
    );
};

like(
    $@,
    qr/does not appear to be a valid media type/,
    "bad audio enclosure - content type"
);

eval {
    my $audio = Net::PMP::Profile::Audio->new(
        title     => 'bad audio enclosure',
        enclosure => [ { href => 'audio.mp3', type => 'audio/mpeg' }, ],
    );
};

like( $@, qr/is not a valid href/, "bad audio enclosure - href" );

# subclassing

{

    package My::Profile;
    use Mouse;
    extends 'Net::PMP::Profile';
    has 'misc_links' =>
        ( is => 'rw', isa => 'Net::PMP::Type::Links', coerce => 1, );
}

ok( my $my_profile = My::Profile->new(
        misc_links => ['http://pmp.io/test'],
        permission => 'http://mpr.org/permission/granted',
        title      => 'i am a my::profile',
    ),
    "new My::Profile"
);
ok( my $my_doc = $my_profile->as_doc, "my_profile->as_doc" );

#diag( dump $my_doc );
is_deeply(
    $my_doc->attributes,
    { hreflang => "en", title => "i am a my::profile" },
    "attributes detected"
);
is_deeply(
    $my_doc->links,
    {   misc_links => [ { href => "http://pmp.io/test" } ],
        permission => [
            {   href      => "http://mpr.org/permission/granted",
                operation => 'read',
            }
        ],
        profile => [
            {   href  => "https://api.pmp.io/profiles/base",
                title => "My::Profile"
            },
        ],
    },
    "links detected"
);
