package Net::PMP::CollectionDoc::Items;
use Mouse;
use Carp;
use Data::Dump qw( dump );
use Net::PMP::CollectionDoc::Item;

has 'items' => ( is => 'rw', isa => 'ArrayRef', required => 1 );
has 'total' => ( is => 'ro', isa => 'Int',      required => 1 );
has 'navlinks' => ( is => 'ro', isa => 'Object', );

__PACKAGE__->meta->make_immutable();

sub as_array {
    my $self = shift;
    return $self->items;
}

sub next {
    my $self = shift;
    $self->{_idx} ||= 0;
    my $items = $self->items;
    my $count = scalar(@$items);

    # grab reference for convenience
    my $i = \$self->{_idx};
    if ( $count <= ++$$i ) {
        return undef;
    }
    while (
        $count >= $$i
        and ( !defined $items->[$$i]
            or ref( $items->[$$i] ) ne 'HASH' )
        )
    {
        warn "[$count] invalid Items object at $$i : "
            . dump( $items->[$$i] );
        $$i++;
        if ( $count <= $$i ) {
            return undef;
        }
    }
    return Net::PMP::CollectionDoc::Item->new( $items->[$$i] );
}

sub count {
    my $self = shift;
    return $self->{_idx};
}

sub reset {
    my $self = shift;
    $self->{_idx} = 0;
}

1;

__END__

=head1 NAME

Net::PMP::CollectionDoc::Items - items from a Net::PMP::CollectionDoc

=head1 SYNOPSIS

 # TODO

=head1 METHODS

=head2 as_array

Returns object as an array.

=head2 next

Standard iterator method. Returns the next L<Net::PMP::CollectionDoc::Item> from the stack.

=head2 count

Returns integer indidating the number of Items returned so far via next().

=head2 reset

Re-initialize the iterator.

=head1 AUTHOR

Peter Karman, C<< <pkarman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-pmp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-PMP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::PMP::CollectionDoc::Items


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
