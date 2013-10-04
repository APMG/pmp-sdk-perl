package Net::PMP::AuthToken;
use Mouse;
use Carp;

has 'access_token'     => ( is => 'rw', isa => 'Str', required => 1, );
has 'token_type'       => ( is => 'rw', isa => 'Str', required => 1, );
has 'token_issue_date' => ( is => 'rw', isa => 'Str', required => 1, );
has 'token_expires_in' => ( is => 'rw', isa => 'Int', required => 1, );

__PACKAGE__->meta->make_immutable();

our $VERSION = '0.01';

sub expires_in { shift->token_expires_in(@_) }

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
