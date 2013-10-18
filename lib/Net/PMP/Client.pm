package Net::PMP::Client;
use Mouse;
use Carp;
use Data::Dump qw( dump );
use LWP::UserAgent 6;    # SSL verification bug fixed in 6.03
use HTTP::Request;
use MIME::Base64;
use JSON;
use Net::PMP::AuthToken;
use Net::PMP::CollectionDoc;

our $VERSION = '0.01';

has 'host' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    default  => 'https://api-sandbox.pmp.io/',
);
has 'id'     => ( is => 'rw', isa => 'Str',  required => 1, );
has 'secret' => ( is => 'rw', isa => 'Str',  required => 1, );
has 'debug'  => ( is => 'rw', isa => 'Bool', default  => 0, );
has 'ua' => ( is => 'rw', isa => 'LWP::UserAgent', builder => '_init_ua', );
has 'auth_endpoint' =>
    ( is => 'rw', isa => 'Str', default => '/auth/access_token', );
has 'pmp_content_type' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'application/vnd.pmp.collection.doc+json',
);
has 'last_response' => ( is => 'rw', isa => 'HTTP::Response', );

# some constructor-time setup
sub BUILD {
    my $self = shift;
    $self->{host} =~ s/\/$//;    # no trailing slash
    $self->{_last_token_ts} = 0;
    $self->get_token();               # initiate connection
    $self->_set_base_doc_config();    # basic introspection
    return $self;
}

sub _init_ua {
    my $self = shift;
    my $ua   = LWP::UserAgent->new(
        agent    => 'net-pmp-perl-' . $VERSION,
        ssl_opts => { verify_hostname => 1 },
    );

# if Compress::Zlib is installed, this should handle gzip transparently.
# thanks to
# http://stackoverflow.com/questions/1285305/how-can-i-accept-gzip-compressed-content-using-lwpuseragent
    my $can_accept = HTTP::Message::decodable();
    $ua->default_header( 'Accept-Encoding' => $can_accept );

    if ( $self->debug ) {
        $ua->add_handler( "request_send",  sub { shift->dump; return } );
        $ua->add_handler( "response_done", sub { shift->dump; return } );
    }

    return $ua;
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Net::PMP::Client - Perl client for the Public Media Platform

=head1 SYNOPSIS

 use Net::PMP::Client;
 
 my $host = 'https://api-sandbox.pmp.io';
 my $client_id = 'i-am-a-client';
 my $client_secret = 'i-am-a-secret';

 # instantiate a client
 my $client = Net::PMP::Client->new(
     host   => $host,
     id     => $client_id,
     secret => $client_secret,
 ); 

 # authenticate
 my $token = $client->get_token();
 if ($token->expires_in() < 10) {
     die "Access token expires too soon. Not enough time to make a request. Mayday, mayday!";
 }
 printf("PMP token is: %s\n, $token->as_string());

 # search
 my $search_results = $client->search({ tag => 'samplecontent', profile => 'story' });  
 my $results = $search_results->get_items();
 printf( "total: %s\n", $results->total );
 while ( my $r = $results->next ) { 
     printf( '%s: %s [%s]', $results->count, $r->get_uri, $r->get_title, ) );
 }   
 
=cut

=head1 DESCRIPTION

Net::PMP::Client is a Perl client for the Public Media Platform API (http://docs.pmp.io/).

=head1 METHODS

=head2 new( I<args> )

Instantiate a Client object. I<args> may consist of:

=over

=item host

Default is C<https://api-sandbox.pmp.io>.

=item id (required)

The client id. See L<https://github.com/publicmediaplatform/pmpdocs/wiki/Authenticating-with-the-API#generating-credentials>.

=item secret (required)

The client secret. See L<https://github.com/publicmediaplatform/pmpdocs/wiki/Authenticating-with-the-API#generating-credentials>.

=item debug

Boolean. Default is off.

=item ua

A LWP::UserAgent object.

=item pmp_content_type

Defaults to C<application/vnd.pmp.collection.doc+json>. Change at your peril.

=back

=head2 BUILD

Internal method for object construction.

=head2 last_response

Returns the most recent HTTP::Response object. Useful for debugging client behaviour.

=head2 get_token([I<refresh>])

Returns a Net::PMP::AuthToken object. The optional I<refresh> boolean indicates
that the Client should ignore any cached token and fetch a fresh one.

=cut

sub get_token {
    my $self = shift;
    my $refresh = shift || 0;

    # use cache?
    if ( !$refresh and $self->{_token} ) {
        my $tok = $self->{_token};
        if ( $self->{_last_token_ts} ) {
            $tok->expires_in(
                $tok->expires_in - ( time() - $self->{_last_token_ts} ) );
        }
        $self->{_last_token_ts} = time();
        return $tok;
    }

    # fetch new token
    my $uri     = $self->host . $self->auth_endpoint;
    my $request = HTTP::Request->new( POST => $uri );
    my $hash    = encode_base64( join( ':', $self->id, $self->secret ), '' );
    $request->header( 'Accept'       => 'application/json' );
    $request->header( 'Content-Type' => 'application/x-www-form-urlencoded' );
    $request->header( 'Authorization' => 'Basic ' . $hash );
    $request->content('grant_type=client_credentials');
    my $response = $self->ua->request($request);

    if ( $response->code != 200 ) {
        croak "Invalid response from authn server: " . $response->status_line;
    }

    $self->last_response($response);

    # unpack response
    my $token;
    eval { $token = decode_json( $response->decoded_content ); };
    if ($@) {
        croak "Invalid authn response: " . $response->decoded_content;
    }
    $self->{_token}         = Net::PMP::AuthToken->new($token);
    $self->{_last_token_ts} = time();
    return $self->{_token};
}

=head2 revoke_token

Expires the currently active AuthToken.

=cut

sub revoke_token {
    my $self    = shift;
    my $uri     = $self->host . $self->auth_endpoint;
    my $hash    = encode_base64( join( ':', $self->id, $self->secret ), '' );
    my $request = HTTP::Request->new( DELETE => $uri );
    $request->header( 'Authorization' => 'Basic ' . $hash );
    my $response = $self->ua->request($request);

    if ( $response->code != 204 ) {
        croak "Invalid response from authn server: " . $response->status_line;
    }
    $self->{_token} = undef;
    return $self;
}

=head2 get(I<uri>)

Issues a GET request on I<uri> and decodes the JSON response into a Perl
scalar.

If the GET request returns a 404 (Not Found) will return 0 (zero).

If the GET request returns anything other than 200, will croak.

If the GET request returns 200, will return the JSON response, decoded.

=cut

sub get {
    my $self    = shift;
    my $uri     = shift or croak "uri required";
    my $request = HTTP::Request->new( GET => $uri );
    my $token   = $self->get_token();
    $request->header(
        'Accept' => 'application/json; ' . $self->pmp_content_type, );
    $request->header( 'Authorization' =>
            sprintf( '%s %s', $token->token_type, $token->access_token ) );
    my $response = $self->ua->request($request);

    # retry if 401
    if ( $response->code == 401 ) {

        # occasional persistent 401 errors?
        sleep(1);
        $token = $self->get_token(1);
        $request->header( 'Authorization' =>
                sprintf( '%s %s', $token->token_type, $token->access_token )
        );

        #sleep(1);
        $response = $self->ua->request($request);
        $self->debug and warn "retry GET $uri\n" . dump($response);
    }

    $self->last_response($response);

    if ( $response->code == 404 ) {
        return 0;
    }

    if ( $response->code != 200 or !$response->decoded_content ) {
        croak "Unexpected response for GET $uri: " . $response->status_line;
    }

    my $json;
    eval { $json = decode_json( $response->decoded_content ); };
    if ($@) {
        croak "Invalid JSON in response: $@ : " . $response->decoded_content;
    }
    return $json;
}

sub _set_base_doc_config {
    my $self = shift;
    $self->{_base_doc} ||= $self->get_doc();
    my $edit_links = $self->{_base_doc}->get_links('edit');
    $self->{_doc_edit_link}
        = $edit_links->rels("urn:pmp:form:documentsave")->[0];
}

=head2 get_doc_edit_link

Retrieves the base doc edit link object for the API.

=cut

sub get_doc_edit_link {
    my $self = shift;
    return $self->{_doc_edit_link} if $self->{_doc_edit_link};
    $self->_set_base_doc_config();
    return $self->{_doc_edit_link};
}

=head2 put(I<doc_object>)

Write I<doc_object> to the server. I<doc_object> should be an instance
of L<Net::PMP::CollectionDoc>.

Returns the JSON response from the server on success, croaks on failure.
Normally you should use save() instead of put() directly.

=cut

sub put {
    my $self = shift;
    my $doc = shift or croak "doc required";
    if ( !blessed $doc or !$doc->isa('Net::PMP::CollectionDoc') ) {
        croak "doc must be a Net::PMP::CollectionDoc object";
    }
    my $uri     = $doc->get_publish_uri( $self->get_doc_edit_link );
    my $request = HTTP::Request->new( PUT => $uri );
    my $token   = $self->get_token();
    $request->header( 'Accept'       => 'application/json' );
    $request->header( 'Content-Type' => $self->pmp_content_type );
    $request->header( 'Authorization' =>
            sprintf( '%s %s', $token->token_type, $token->access_token ) );
    $request->content( $doc->as_json() );
    my $response = $self->ua->request($request);

    # retry if 401
    if ( $response->code == 401 ) {

        # occasional persistent 401 errors?
        sleep(1);
        $token = $self->get_token(1);
        $request->header( 'Authorization' =>
                sprintf( '%s %s', $token->token_type, $token->access_token )
        );

        #sleep(1);
        $response = $self->ua->request($request);
        $self->debug and warn "retry PUT $uri\n" . dump($response);
    }

    $self->last_response($response);

    if ( $response->code !~ m/^20[02]$/ or !$response->decoded_content ) {
        croak sprintf( "Unexpected response for PUT %s: %s\n%s\n",
            $uri, $response->status_line, $response->content );
    }

    my $json;
    eval { $json = decode_json( $response->decoded_content ); };
    if ($@) {
        croak "Invalid JSON in response: $@ : " . $response->decoded_content;
    }
    return $json;
}

=head2 delete(I<doc_object>)

Remove I<doc_object> from the server. Returns true on success, croaks on failure.

=cut

sub delete {
    my $self = shift;
    my $doc = shift or croak "doc required";
    if ( !blessed $doc or !$doc->isa('Net::PMP::CollectionDoc') ) {
        croak "doc must be a Net::PMP::CollectionDoc object";
    }
    my $uri     = $doc->get_publish_uri( $self->get_doc_edit_link );
    my $request = HTTP::Request->new( DELETE => $uri );
    my $token   = $self->get_token();
    $request->header( 'Accept'       => 'application/json' );
    $request->header( 'Content-Type' => $self->pmp_content_type );
    $request->header( 'Authorization' =>
            sprintf( '%s %s', $token->token_type, $token->access_token ) );
    my $response = $self->ua->request($request);

    # retry if 401
    if ( $response->code == 401 ) {

        # occasional persistent 401 errors?
        sleep(1);
        $token = $self->get_token(1);
        $request->header( 'Authorization' =>
                sprintf( '%s %s', $token->token_type, $token->access_token )
        );

        $response = $self->ua->request($request);
        $self->debug and warn "retry DELETE $uri\n" . dump($response);
    }

    $self->last_response($response);

    if ( $response->code != 204 ) {
        croak sprintf( "Unexpected response for DELETE %s: %s\n%s\n",
            $uri, $response->status_line, $response->content );
    }
    return 1;
}

=head2 get_doc([I<uri>]) 

Returns a Net::PMP::CollectionDoc representing I<uri>. Defaults
to the API base endpoint if I<uri> is omitted.

If I<uri> is not found, returns 0 (zero) just like get().

=cut

sub get_doc {
    my $self = shift;
    my $uri = shift || $self->host;

    my $response = $self->get($uri);

    # convert JSON response into a CollectionDoc
    $self->debug and warn dump $response;

    return $response unless $response;    # 404

    my $doc = Net::PMP::CollectionDoc->new($response);

    return $doc;
}

=head2 search( I<opts> )

Returns a Net::PMP::CollectionDoc object for I<opts>.
I<opts> are passed directly to the query link URI template.
See L<https://github.com/publicmediaplatform/pmpdocs/wiki/Query-Link-Relation>.

=cut

sub search {
    my $self = shift;
    my $opts = shift or croak "options required";
    my $uri  = $self->{_base_doc}->query('urn:pmp:query:docs')->as_uri($opts);
    return $self->get_doc($uri);
}

=head2 save(I<doc_object>)

Write I<doc_object> to the server. Returns the I<doc_object>
with its URI updated to reflect the server response. Wraps
put() internally.

=cut

sub save {
    my $self = shift;
    my $doc = shift or croak "doc object required";
    if ( !blessed $doc or !$doc->isa('Net::PMP::CollectionDoc') ) {
        croak "doc must be a Net::PMP::CollectionDoc object";
    }

    # if $doc has no guid (necessary for PUT) create one
    if ( !$doc->get_guid ) {
        $doc->set_guid();
    }
    my $saved = $self->put($doc);
    $self->debug and warn dump $saved;

    $doc->set_uri( $saved->{url} );

    return $doc;
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <pkarman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-pmp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-PMP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::PMP::Client


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
