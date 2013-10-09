use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Net::PMP',
    AUTHOR             => q{Peter Karman <pkarman@cpan.org>},
    VERSION_FROM       => 'lib/Net/PMP.pm',
    ABSTRACT_FROM      => 'lib/Net/PMP.pm',
    LICENSE            => 'MIT',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.008009,
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => 0, },
    BUILD_REQUIRES     => { 'Test::More' => 0, },
    PREREQ_PM          => {
        'Mouse'          => 0,
        'Test::More'     => 0,
        'JSON'           => 2.0,
        'LWP::UserAgent' => 0,
        'Data::Dump'     => 0,
        'URI::Template'  => 0,
        'UUID::Tiny'     => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Net-PMP-*' },
);
