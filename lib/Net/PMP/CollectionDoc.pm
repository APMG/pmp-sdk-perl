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
