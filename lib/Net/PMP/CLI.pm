package Net::PMP::CLI;
use Mouse;
with 'MouseX::SimpleConfig';
with 'MouseX::Getopt';

use Net::PMP::Client;
use Data::Dump qw( dump );

has '+configfile' => ( default => $ENV{HOME} . '/.pmp.yaml' );
has 'debug'       => ( is      => 'rw', isa => 'Bool', );
has 'id'          => ( is      => 'rw', isa => 'Str', required => 1, );
has 'secret'      => ( is      => 'rw', isa => 'Str', required => 1, );
has 'host' =>
    ( is => 'rw', isa => 'Str', default => 'https://api-sandbox.pmp.io', );
has 'profile' => ( is => 'rw', isa => 'Str' );
has 'title'   => ( is => 'rw', isa => 'Str', );
has 'path'    => ( is => 'rw', isa => 'Str', );
has 'guid'    => ( is => 'rw', isa => 'Str', );

sub run {
    my $self = shift;

    $self->debug and dump $self;

    my @cmds = @{ $self->extra_argv };

    if ( !@cmds or $self->help_flag ) {
        die $self->usage;
    }

    for my $cmd (@cmds) {
        if ( !$self->can($cmd) ) {
            warn "No such command $cmd\n";
            die $self->usage;
        }
        $self->$cmd();
    }

}

sub _list_items {
    my ( $self, $label, $urn ) = @_;
    my $client = $self->init_client();
    my $root   = $client->get_doc();
    my $q      = $root->query($urn);
    my $uri    = $q->as_uri( {} );
    my $res    = $client->get_doc($uri) or return;
    my $items  = $res->get_items();
    while ( my $item = $items->next ) {
        printf( "%s: %s [%s] [%s]\n",
            $label, $item->get_title, $item->get_guid, $item->get_profile, );
    }
}

sub create {
    my $self    = shift;
    my $profile = $self->profile or die "--profile required for create\n";
    my $title   = $self->title or die "--title required for create\n";
    my $client  = $self->init_client;

    # verify profile first
    my $prof_doc = $self->get( '/profiles/' . $profile );
    if ( !$prof_doc ) {
        die "invalid profile: $profile\n";
    }
    my $doc = Net::PMP::CollectionDoc->new(
        version    => $client->get_doc->version,
        attributes => { title => $title, },
        links      => {
            profile => [ { href => $client->host . '/profiles/' . $profile } ]
        },
    );
    $client->save($doc);
    printf( "%s saved as %s at %s\n",
        $profile, $doc->get_title, $doc->get_uri );
}

sub delete {
    my $self   = shift;
    my $guid   = $self->guid or die "--guid required for delete\n";
    my $client = $self->init_client;
    my $doc    = $client->search( { guid => $guid } );
    if ( !$doc ) {
        die "Cannot delete non-existent doc $guid\n";
    }
    $client->delete($doc);
}

sub users {
    my $self = shift;
    my $urn  = "urn:pmp:query:users";
    $self->_list_items( 'User', $urn );
}

sub groups {
    my $self = shift;
    my $urn  = "urn:pmp:query:groups";
    $self->_list_items( 'Group', $urn );
}

sub get {
    my $self = shift;
    if ( !$self->path ) {
        die "--path required for get\n";
    }
    my $client = $self->init_client;
    my $uri    = $client->host . $self->path;
    my $doc    = $client->get_doc($uri);
    if ( $doc eq '0' ) {
        printf( "No such path: %s [%s]\n",
            $self->path, $client->last_response->status_line );
    }
    else {
        dump $doc;
    }
}

sub init_client {
    my $self = shift;
    return $self->{_client} if $self->{_client};
    my $client = Net::PMP::Client->new(
        id     => $self->id,
        secret => $self->secret,
        host   => $self->host,
        debug  => $self->debug,
    );
    $self->{_client} = $client;
    return $client;
}

1;

