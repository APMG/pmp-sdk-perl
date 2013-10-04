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

