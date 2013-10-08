package Net::PMP::CollectionDoc::Link;
use Mouse;
use Carp;
use Data::Dump qw( dump );
use URI::Template;

has 'hints'      => ( is => 'rw', isa => 'HashRef' );
has 'template'   => ( is => 'rw', isa => 'Str' );
has 'vars'       => ( is => 'rw', isa => 'HashRef' );
has 'rels'       => ( is => 'rw', isa => 'ArrayRef', );
has 'title'      => ( is => 'rw', isa => 'Str' );
has 'href'       => ( is => 'rw', isa => 'Str' );
has 'method'     => ( is => 'rw', isa => 'Str' );
has 'type'       => ( is => 'rw', isa => 'Str' );
has 'pagenum'    => ( is => 'rw', isa => 'Int' );
has 'totalpages' => ( is => 'rw', isa => 'Int' );
has 'totalitems' => ( is => 'rw', isa => 'Int' );

sub options {
    my $self = shift;
    if ( $self->vars and $self->template ) {
        return $self->vars;
    }
    else {
        croak "Link is not a properly defined href template";
    }
}

sub as_uri {
    my $self = shift;
    my $options = shift or croak "options required";
    if ( !$self->template ) {
        croak "No template defined in Link";
    }
    my $tmpl = URI::Template->new( $self->template );
    return $tmpl->process( $self->_mangle_options($options) );
}

sub _coerce_opt {
    my $self = shift;
    my $opt  = shift;

    # may be of the form:
    # ['AND' => ['foo', 'bar']] or
    # ['foo','bar'] or
    # ['OR' => ['foo','bar']]
    if ( $opt->[0] eq 'AND' ) {
        return join( ',', @{ $opt->[1] } );
    }
    elsif ( $opt->[0] eq 'OR' ) {
        return join( ';', @{ $opt->[1] } );
    }
    else {
        return join( ',', @$opt );    # assume AND
    }
}

sub _mangle_options {
    my $self = shift;
    my $opts = shift;
    my %mangled;
    for my $key ( keys %$opts ) {
        if ( ref $opts->{$key} eq 'ARRAY' ) {
            $mangled{$key} = $self->_coerce_opt( $opts->{$key} );
        }
        elsif ( ref $opts->{$key} ) {
            croak "unsupported reference for option '$key'";
        }
        else {
            $mangled{$key} = $opts->{$key};
        }
    }
    return \%mangled;
}

__PACKAGE__->meta->make_immutable();

1;

__END__

=head1 NAME

Net::PMP::CollectionDoc::Link - link from a Net::PMP::CollectionDoc::Links object

=head1 SYNOPSIS

 # TODO

=head1 DESCRIPTION

Net::PMP::CollectionDoc::Link represents a link in a Collection.doc+JSON PMP API response.

=head1 METHODS

=head2 hints

=head2 href

=head2 title

=head2 rels

=head2 vars

=head2 template

=head2 method

=head2 type

=head2 options

=head2 as_uri(I<options>)

Applies I<options> hashref against the template() value and returns a URI object.

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
