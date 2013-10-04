package Net::PMP::CollectionDoc::Links;
use Mouse;
use Carp;
use Data::Dump qw( dump );

has 'links' => ( is => 'rw', isa => 'ArrayRef', required => 1, );
has 'type'  => ( is => 'rw', isa => 'Str',      required => 1, );

sub query_rel_types {
    my $self = shift;
    if ( $self->type ne 'query' ) {
        croak "Can't call query_rel_types on Links object of type "
            . $self->type;
    }
    my %t;
    for my $link ( @{ $self->links } ) {
        $t{ $link->{rels}->[0] } = $link->{title};
    }
    return \%t;
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
