package Net::PMP::CollectionDoc;
use Mouse;
use Carp;
use Data::Dump qw( dump );
use Net::PMP::CollectionDoc::Links;
use Net::PMP::CollectionDoc::Items;

has 'links'      => ( is => 'ro', isa => 'HashRef',  required => 1, );
has 'attributes' => ( is => 'ro', isa => 'HashRef',  required => 1, );
has 'version'    => ( is => 'ro', isa => 'Str',      required => 1, );
has 'items'      => ( is => 'ro', isa => 'ArrayRef', required => 0, );

sub get_links {
    my $self  = shift;
    my $type  = shift or croak "type required";
    my $links = $self->links->{$type} or croak "No such type $type";
    return Net::PMP::CollectionDoc::Links->new(
        type  => $type,
        links => $links
    );
}

sub get_items {
    my $self = shift;
    if ( !$self->items ) {
        croak "No items defined for CollectionDoc";
    }
    my $navlinks = $self->get_links('navigation');
    my $navself  = $navlinks->rels('urn:pmp:navigation:self')->[0];
    my $total    = $navself->totalitems;
    return Net::PMP::CollectionDoc::Items->new(
        items    => $self->items,
        navlinks => $navlinks,
        total    => $total,
    );
}

sub query {
    my $self        = shift;
    my $urn         = shift or croak "URN required";
    my $query_links = $self->get_links('query');
    my $rels        = $query_links->rels($urn);
    if (@$rels) {
        return $rels->[0];    # first link found
    }
    return undef;
}

1;

__END__

=head1 NAME

Net::PMP::CollectionDoc - Collection.doc+JSON object for Net::PMP::Client

=head1 SYNOPSIS

 my $doc = $pmp_client->get_doc();
 printf("API version: %s\n", $doc->version);
 my $query_links = $doc->get_links('query');

=head1 DESCRIPTION

Net::PMP::CollectionDoc represents the PMP API media type L<https://github.com/publicmediaplatform/pmpdocs/wiki/Collection.doc-JSON-Media-Type>.

=head1 METHODS

=head2 get_links( I<type> )

Returns Net::PMP::CollectionDoc::Links object for I<type>, which may be one of:

=over

=item creator

=item edit

=item navigation

=item query

=back

=head2 links

Returns hashref of link data.

=head2 attributes

Returns hashref of attribute data.

=head2 version

Returns API version string.

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
