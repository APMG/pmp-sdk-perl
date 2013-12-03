package Net::PMP::Profile::Story;
use Mouse;
extends 'Net::PMP::Profile';

our $VERSION = '0.01';

has 'teaser'           => ( is => 'rw', isa => 'Str', );
has 'contentencoded'   => ( is => 'rw', isa => 'Str', );
has 'contenttemplated' => ( is => 'rw', isa => 'Str', );

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

Net::PMP::Profile::Story implements the CollectionDoc fields for the PMP Story Profile
L<https://github.com/publicmediaplatform/pmpdocs/wiki/Story-Profile>.

=head1 METHODS

This class extends L<Net::PMP::Profile>. Only new or overridden methods are documented here.

=head2 teaser

Optional brief summary.

=head2 contentencoded

Optional full HTML-encoded string.

=head2 contenttemplated

Optional content with placeholders for rich media assets.

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
