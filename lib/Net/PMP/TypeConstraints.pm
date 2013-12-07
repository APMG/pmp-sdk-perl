package Net::PMP::TypeConstraints;
use Mouse;
use Mouse::Util::TypeConstraints;

# The Net::PMP::Type::* prefix is used for all our type constraints
# to avoid stepping on anyone's toes

# locales
use Locale::Language;
my %all_langs = map { $_ => $_ } all_language_codes();
subtype 'Net::PMP::Type::ISO6391' => as 'Str' =>
    where { length($_) == 2 and exists $all_langs{$_} } =>
    message {"The provided hreflang ($_) is not a valid ISO639-1 value."};

# datetimes
use DateTime::Format::ISO8601;
use DateTime::Format::Strptime;
my $coerce_datetime = sub {
    my $thing = shift;
    my $iso8601_formatter
        = DateTime::Format::Strptime->new( pattern => '%FT%T.%3NZ' );
    if ( blessed $thing) {
        if ( $thing->isa('DateTime') ) {
            $thing->set_formatter($iso8601_formatter);
            return $thing;
        }
        confess "$thing is not a DateTime object";
    }
    else {
        my $dt = DateTime::Format::ISO8601->parse_datetime($thing);
        $dt->set_formatter($iso8601_formatter);
        return $dt;
    }
};
subtype 'Net::PMP::Type::DateTimeOrStr' => as class_type('DateTime');
coerce 'Net::PMP::Type::DateTimeOrStr'  => from 'Object' =>
    via { $coerce_datetime->($_) } => from 'Str' =>
    via { $coerce_datetime->($_) };
subtype 'Net::PMP::Type::ValidDates' => as
    'HashRef[Net::PMP::Type::DateTimeOrStr]';
coerce 'Net::PMP::Type::ValidDates' => from 'HashRef' => via {
    if ( !exists $_->{to} or !exists $_->{from} ) {
        confess "ValidDates must contain 'to' and 'from' keys";
    }
    $_->{to}   = $coerce_datetime->( $_->{to} );
    $_->{from} = $coerce_datetime->( $_->{from} );
    $_;
};

# links
my $coerce_link = sub {

    # defer till runtime to avoid circular dependency
    require Net::PMP::CollectionDoc::Link;

    if ( ref( $_[0] ) eq 'HASH' ) {
        return Net::PMP::CollectionDoc::Link->new( $_[0] );
    }
    elsif ( blessed $_[0] ) {
        return $_[0];
    }
    else {
        return Net::PMP::CollectionDoc::Link->new( href => $_[0] );
    }
};
subtype 'Net::PMP::Type::Link' =>
    as class_type('Net::PMP::CollectionDoc::Link');
coerce 'Net::PMP::Type::Link' => from 'Any' => via { $coerce_link->($_) };
subtype 'Net::PMP::Type::Links' => as 'ArrayRef[Net::PMP::Type::Link]';
coerce 'Net::PMP::Type::Links' => from 'ArrayRef' => via {
    [ map { $coerce_link->($_) } @$_ ];
} => from 'HashRef' => via { [ $coerce_link->($_) ] } => from 'Any' =>
    via { [ $coerce_link->($_) ] };

# Content types
use Media::Type::Simple qw(is_type);

#confess "MediaType defined!";
subtype 'Net::PMP::Type::MediaType' => as 'Str' => where {
    is_type($_);
} => message {
    "The value ($_) does not appear to be a valid media type.";
};

# URIs
use Data::Validate::URI qw(is_uri);
subtype 'Net::PMP::Type::Href' => as 'Str' => where {
    is_uri($_);
} => message {"Value ($_) is not a valid href."};

# MediaEnclosure
my $coerce_enclosure = sub {

    # defer till runtime to avoid circular dependency
    require Net::PMP::MediaEnclosure;

    if ( ref( $_[0] ) eq 'HASH' ) {
        return Net::PMP::MediaEnclosure->new( $_[0] );
    }
    else { return $_[0]; }
};
subtype 'Net::PMP::Type::MediaEnclosure' =>
    as class_type('Net::PMP::MediaEnclosure');
coerce 'Net::PMP::Type::MediaEnclosure' => from 'Any' =>
    via { $coerce_enclosure->($_) };
subtype 'Net::PMP::Type::MediaEnclosures' => as
    'ArrayRef[Net::PMP::Type::MediaEnclosure]';
coerce 'Net::PMP::Type::MediaEnclosures' => from 'ArrayRef[HashRef]' => via {
    [ map { $coerce_enclosure->($_) } @$_ ];
} => from 'HashRef' => via { [ $coerce_enclosure->($_) ] };

no Mouse::Util::TypeConstraints;

__PACKAGE__->meta->make_immutable();

1;

__END__

=head1 NAME

Net::PMP::CollectionDoc::Link - link from a Net::PMP::CollectionDoc::Links object

=head1 SYNOPSIS

 package My::Class;
 use Mouse;
 use Net::PMP::TypeConstraints;

 # provide validation checking
 has 'uri' => (isa => 'Net::PMP::Type::Href');

 1;

=head1 DESCRIPTION

Net::PMP::TypeConstraints defines validation constraints for Net::PMP classes.
This is a utility class defining types with L<Mouse::Util::TypeConstraints>
in the C<Net::PMP::Type> namespace.

=head1 AUTHOR

Peter Karman, C<< <pkarman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-pmp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-PMP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::PMP::CollectionDoc::Link


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-PMP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-PMP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-PMP>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-PMP/>

=back


=head1 ACKNOWLEDGEMENTS

American Public Media and the Public Media Platform sponsored the development of this module.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 American Public Media Group

See the LICENSE file that accompanies this module.

=cut

