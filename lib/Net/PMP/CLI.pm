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

=head1 NAME

Net::PMP::CLI - command line application for Net::PMP::Client

=head1 SYNOPSIS

 use Net::PMP::CLI;
 my $app = Net::PMP::CLI->new_with_options();
 $app->run();

=head1 DESCRIPTION

This class is used by the C<pmpc> command-line tool.
It uses L<MouseX::SimpleConfig> and L<MouseX::Getopt> to allow
for simple configuration file and option parsing.

=head1 METHODS

With the exceptions of B<run> and B<init_client> all method
names are commands.

=head2 run

Main method. Calls commands passed via @ARGV.

=cut

sub run {
    my $self = shift;

    $self->debug and dump $self;

    my @cmds = @{ $self->extra_argv };

    if ( !@cmds or $self->help_flag ) {
        $self->usage->die( { post_text => $self->commands } );
    }

    for my $cmd (@cmds) {
        if ( !$self->can($cmd) ) {
            warn "No such command $cmd\n";
            $self->usage->die( { post_text => $self->commands } );
        }
        $self->$cmd();
    }

}

sub commands {
    my $self = shift;
    my $txt  = <<EOF;
commands:
    create  --profile <profile> --title <title>
    delete  --guid <guid>
    get     --path /path/to/resource
    groups
    users
EOF
    return $txt;
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

=head2 create

Create or update a resource via Net::PMP::Client.
Requires the C<--profile> and C<--title> options.

=cut

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

=head2 delete

Deletes a resource. Requires the C<--guid> option.

=cut

sub delete {
    my $self   = shift;
    my $guid   = $self->guid or die "--guid required for delete\n";
    my $client = $self->init_client;
    my $doc    = $client->get_doc_by_guid($guid);
    if ( !$doc ) {
        die "Cannot delete non-existent doc $guid\n";
    }
    if ( $client->delete($doc) ) {
        printf( "Deleted %s\n", $guid );
    }
    else {
        printf( "Failed to delete %s\n", $guid );    # never get here, croaks
    }
}

=head2 users

List all users.

=cut

sub users {
    my $self = shift;
    my $urn  = "urn:pmp:query:users";
    $self->_list_items( 'User', $urn );
}

=head2 groups

List all groups.

=cut

sub groups {
    my $self = shift;
    my $urn  = "urn:pmp:query:groups";
    $self->_list_items( 'Group', $urn );
}

=head2 get([I<path>])

Issues a get_doc() for the URI represented by I<path>. If I<path>
is not explicitly passed, looks at the C<--path> option.

Dumps the resource for I<path> to stdout.

=cut

sub get {
    my $self = shift;
    my $path = shift || $self->path;
    if ( !$path ) {
        die "--path required for get\n";
    }
    my $client = $self->init_client;
    my $uri    = $client->host . $path;
    my $doc    = $client->get_doc($uri);
    if ( $doc eq '0' ) {
        printf( "No such path: %s [%s]\n",
            $self->path, $client->last_response->status_line );
    }
    else {
        dump $doc;
    }
}

=head2 init_client

Instantiates and caches a Net::PMP::Client instance.

=cut

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
