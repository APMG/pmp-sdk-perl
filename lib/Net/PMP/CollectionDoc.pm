package Net::PMP::CollectionDoc;
use Mouse;
use Carp;
use Data::Dump qw( dump );
use Net::PMP::CollectionDoc::Links;

has 'links'      => ( is => 'ro', isa => 'HashRef', required => 1, );
has 'attributes' => ( is => 'ro', isa => 'HashRef', required => 1, );
has 'version'    => ( is => 'ro', isa => 'Str',     required => 1, );

sub get_links {
    my $self  = shift;
    my $type  = shift or croak "type required";
    my $links = $self->links->{$type} or croak "No such type $type";
    return Net::PMP::CollectionDoc::Links->new( type => $type,
        links => $links );
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <pkarman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-pmp-client at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-PMP-Client>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::PMP::Client


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-PMP-Client>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-PMP-Client>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-PMP-Client>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-PMP-Client/>

=back


=head1 ACKNOWLEDGEMENTS

American Public Media and the Public Media Platform sponsored the development of this module.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 American Public Media Group

See the LICENSE file that accompanies this module.

=cut
