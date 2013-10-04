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

