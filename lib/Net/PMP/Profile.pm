package Net::PMP::Profile;
use Mouse;
use DateTime::Format::ISO8601;
use Data::Dump qw( dump );

our $VERSION = '0.01';

{
    use Mouse::Util::TypeConstraints;
    use Locale::Language;
    use Data::Validate::URI qw(is_uri);
    my %all_langs = map { $_ => $_ } all_language_codes();
    subtype 'ISO6391' => as 'Str' =>
        where { length($_) == 2 and exists $all_langs{$_} } =>
        message {"The provided hreflang ($_) is not a valid ISO639-1 value."};
    subtype 'DateTimeOrStr' => as class_type('DateTime');
    coerce 'DateTimeOrStr' => from 'Object' => via {$_} => from 'Str' =>
        via { DateTime::Format::ISO8601->parse_datetime($_) };
    subtype 'ValidDates' => as 'HashRef' => where {

        if ( !exists $_->{to} or !exists $_->{from} ) {
            confess "HashRef must contain 'to' and 'from' keys";
        }
        for my $k ( keys %$_ ) {
            if ( blessed $_->{$k} ) {
                if ( !$_->{$k}->isa('DateTime') ) {
                    confess "value $_->{$k} is not a DateTime object";
                }
            }
            else {
                $_->{$k}
                    = DateTime::Format::ISO8601->parse_datetime( $_->{$k} );
            }
        }
        return $_;
    };
    subtype 'Hrefs' => as 'ArrayRef' => where {
        if ( ref($_) ne 'ARRAY' ) { return 0 }
        for my $u (@$_) {
            if ( !is_uri($u) ) {
                return 0;
            }
        }
        return 1;
    } => message {
        "The value " . dump($_) . " does not appear to be an array of hrefs.";
    };

    no Mouse::Util::TypeConstraints;
}

has 'title'     => ( is => 'rw', isa => 'Str',           required => 1, );
has 'hreflang'  => ( is => 'rw', isa => 'ISO6391',       default  => 'en', );
has 'published' => ( is => 'rw', isa => 'DateTimeOrStr', coerce   => 1, );
has 'valid'     => ( is => 'rw', isa => 'ValidDates', );
has 'tags'        => ( is => 'rw', isa => 'ArrayRef[Str]', );
has 'description' => ( is => 'rw', isa => 'Str', );
has 'byline'      => ( is => 'rw', isa => 'Str', );
has 'author'      => ( is => 'rw', isa => 'Hrefs', );
has 'copyright'   => ( is => 'rw', isa => 'Hrefs', );
has 'distributor' => ( is => 'rw', isa => 'Hrefs', );

1;

__END__

=head1 NAME

Net::PMP::Profile - Base Content Profile for PMP CollectionDoc

=head1 SYNOPSIS

 use Net::PMP;
 use Net::PMP::Profile;
 
 my $profile_doc = Net::PMP::Profile->new(
     title     => 'I am A Title',
     published => '2013-12-03T12:34:56.789Z',
     valid     => {
         from => "2013-04-11T13:21:31.598Z",
         to   => "3013-04-11T13:21:31.598Z",
     },
     byline    => 'By: John Writer and Nancy Author',
     description => 'This is a summary of the document.',
     tags      => [qw( foo bar baz )],
     hreflang  => 'en',  # ISO639-1 code
     author      => [qw( http://api.pmp.io/user/some-guid )],
     copyright   => [qw( http://americanpublicmedia.org/ )],
     distributor => [qw( http://api.pmp.io/organization/different-guid )],
 );

 # instantiate a client
 my $client = Net::PMP->client(
     host   => $host,
     id     => $client_id,
     secret => $client_secret,
 ); 

 # save doc
 $client->save($profile_doc);
 
=cut

=head1 DESCRIPTION

Net::PMP::Profile implements the CollectionDoc fields for the PMP Base Content Profile
L<https://github.com/publicmediaplatform/pmpdocs/wiki/Base-Content-Profile>.

This class B<does not> inherit from L<Net::PMP::CollectionDoc>. Net::PMP::Profile-based
classes are intended to ease data synchronization between PMP and other systems, by
providing client-based attribute validation and syntactic sugar. A CollectionDoc-based
object has no inherent validation for its attributes; it simply reflects what is on 
the PMP server. A Profile-based object can be used to validate attribute values before
they are sent to the PMP server. The B<as_doc> method converts the Profile-based object
to a CollectionDoc-based object.

=head1 METHODS

=head2 title

=head2 hreflang

=head2 valid

=head2 published

Optional ISO 8601 datetime string. You may pass in a DateTime object and as_doc()
will render it correctly.

=head2 byline

Optional attribution string.

=head2 description

Optional summary string.

=head2 tags

Optional keyword array of strings.

=head2 as_doc

Returns a L<Net::PMP::CollectionDoc> object suitable for L<Net::PMP::Client> interaction.

=head1 AUTHOR

Peter Karman, C<< <pkarman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-pmp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-PMP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::PMP


You can also look for information at:

=over 4

=item IRC

Join #pmp on L<http://freenode.net>.

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
