package Net::PMP::MediaEnclosure;
use Mouse;

our $VERSION = '0.01';

{
    use Mouse::Util::TypeConstraints;
    use Data::Validate::URI qw(is_uri);
    use Media::Type::Simple qw(is_type);
    subtype 'Href' => as 'Str' => where {
        is_uri($_);
    } => message {
        "The value ($_) does not appear to be a href.";
    };
    subtype 'MediaType' => as 'Str' => where {
        is_type($_);
    } => message {
        "The value ($_) does not appear to be a valid media type.";
    };

    no Mouse::Util::TypeConstraints;
}

has 'href' => ( is => 'rw', isa => 'Href',      required => 1, );
has 'type' => ( is => 'rw', isa => 'MediaType', required => 1, );
has 'meta' => ( is => 'rw', isa => 'HashRef', );
has 'crop' => ( is => 'rw', isa => 'Str', );
has 'width'      => ( is => 'rw', isa => 'Int', );
has 'height'     => ( is => 'rw', isa => 'Int', );
has 'resolution' => ( is => 'rw', isa => 'Float', );
has 'codec'      => ( is => 'rw', isa => 'Str', );
has 'format'     => ( is => 'rw', isa => 'Str', );
has 'duration'   => ( is => 'rw', isa => 'Int', );

1;

__END__

=head1 NAME

Net::PMP::MediaEnclosure - Rich Media representation for PMP CollectionDoc

=head1 SYNOPSIS

 use Net::PMP::MediaEnclosure;
 
 my $image = Net::PMP::MediaEnclosure->new(
     href        => 'http://mpr.org/some/asset/some/where.png',
     type        => 'images/png'
     crop        => 'medium',
     width       => 100,
     height      => 150',
     resolutionn => 102, # PPI
     meta        => { foo => 'bar' },
 );

 my $audio = Net::PMP::MediaEnclosure->new( 
     href     => 'http://mpr.org/some/audio/some/where.mp3',
     type     => 'audio/mpeg',
     codec    => 'LAME3.99r',
     format   => 'MP3',
     duration => 60000, # milliseconds
     meta     => { foo => 'bar' },
 );

 my $video = Net::PMP::MediaEnclosure->new(
     href     => 'http://mpr.org/some/video/some/where',
     type     => 'video/mpeg',
     codec    => 'Xvid',
     format   => 'MPEG=1',
     duration => 60000, # milliseconds
     meta     => { foo => 'bar' },
 );
 
=cut

=head1 DESCRIPTION

Net::PMP::MediaEnclosure implements the CollectionDoc fields for the PMP Rich Media Profile
L<https://github.com/publicmediaplatform/pmpdocs/wiki/Rich-Media-Profiles>.

=head1 METHODS

=head2 href

URI string.

=head2 type

Content type string.

=head2 meta

Hashref of arbitrary metadata.

=head2 crop

Image label string.

=head2 width

Image width integer.

=head2 height

Image height integer.

=head2 resolution

Image pixels-per-inch float.

=head2 codec

Audio/video codec string.

=head2 format

Audio/video format string.

=head2 duration

Audio/video duration integer (milliseconds). E.g. 60000 == 60 seconds.

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
