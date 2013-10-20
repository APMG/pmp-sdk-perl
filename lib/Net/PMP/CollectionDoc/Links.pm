package Net::PMP::CollectionDoc::Links;
use Mouse;
use Carp;
use Data::Dump qw( dump );
use Net::PMP::CollectionDoc::Link;

has 'links' => (
    is       => 'rw',
    isa      => 'ArrayRef',
    required => 1,
    trigger  => \&_bless_links
);
has 'type' => ( is => 'rw', isa => 'Str', required => 1, );

__PACKAGE__->meta->make_immutable();

sub _bless_links {
    my ( $self, $links ) = @_;
    for my $link (@$links) {
        next if blessed $link;
        my %h = ();
        for my $opt (
            qw( hints href method type title pagenum totalitems totalpages rels )
            )
        {
            if ( $link->{$opt} ) {
                $h{$opt} = $link->{$opt};
            }
        }
        if ( $link->{'href-vars'} ) {
            $h{vars} = $link->{'href-vars'};
        }
        if ( $link->{'href-template'} ) {
            $h{template} = $link->{'href-template'};
        }
        $link = Net::PMP::CollectionDoc::Link->new(%h);
    }
    return $links;
}

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

sub rels {
    my $self = shift;
    my @urns = @_;
    my @links;
    for my $urn (@urns) {
        for my $link ( @{ $self->links } ) {
            for my $rel ( @{ $link->rels || [] } ) {
                if ( $rel eq $urn ) {
                    push @links, $link;
                }
            }
        }
    }
    return \@links;
}

1;

__END__

=head1 NAME

Net::PMP::CollectionDoc::Links - links from a Net::PMP::CollectionDoc

=head1 SYNOPSIS

 # TODO

=head1 DESCRIPTION

Net::PMP::CollectionDoc::Links represents the links in a Collection.doc+JSON PMP API response.

=head1 METHODS

=head2 links

Returns arrayref of links.

=head2 type

The flavor of the Links object.

=head2 query_rel_types

If B<type> is C<query> then this method can used to return a hashref of rel names
to titles.

=head2 rels(I<urn>[, ...I<urn>])

Returns arrayref of links that match I<urn>.

=head1 AUTHOR

Peter Karman, C<< <pkarman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-pmp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-PMP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::PMP::CollectionDoc::Links


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
