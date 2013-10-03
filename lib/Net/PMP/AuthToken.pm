package Net::PMP::AuthToken;
use strict;
use warnings;
use Carp;

use base qw( Rose::ObjectX::CAF );

__PACKAGE__->mk_accessors(
    qw( access_token token_type token_issue_date token_expires_in ));

our $VERSION = '0.01';

sub expires_in { shift->token_expires_in(@_) }

1;

