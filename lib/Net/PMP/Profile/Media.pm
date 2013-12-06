package Net::PMP::Profile::Media;
use Mouse;
extends 'Net::PMP::Profile';
use Net::PMP::MediaEnclosure;

our $VERSION = '0.01';

has 'enclosure' => (
    is       => 'rw',
    isa      => 'Net::PMP::Type::MediaEnclosures',
    required => 1,
    coerce   => 1,
);

sub get_profile_url {'http://api.pmp.io/profiles/media'}

1;

__END__

=head1 NAME

Net::PMP::Profile::Media - Rich Media Profile for PMP CollectionDoc

=head1 SYNOPSIS

 use Net::PMP;
 use Net::PMP::Profile::Media;
 
 my $media = Net::PMP::Profile::Media->new(
     title     => 'I am A Title',
     published => '2013-12-03T12:34:56.789Z',
     valid     => {
         from => "2013-04-11T13:21:31.598Z",
         to   => "3013-04-11T13:21:31.598Z",
     },
     byline    => 'By: John Writer and Nancy Author',
     description => 'This is a summary of the document.',
     tags      => [qw( foo bar baz )],
     enclosure => [
         
     ],
 );

 # instantiate a client
 my $client = Net::PMP->client(
     host   => $host,
     id     => $client_id,
     secret => $client_secret,
 ); 

 # save doc
 $client->save($media);
 
=cut

=head1 DESCRIPTION

Net::PMP::Profile::Media implements the CollectionDoc fields for the PMP Rich Media Profile
L<https://github.com/publicmediaplatform/pmpdocs/wiki/Rich-Media-Profiles>.

=head1 METHODS

This class extends L<Net::PMP::Profile>. Only new or overridden methods are documented here.

=head2 enclosure

Required array of hashrefs or Net::PMP::MediaEnclosure objects representing the binary file of the media asset.

=head2 get_profile_url

Returns a string for the PMP profile's URL.

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
