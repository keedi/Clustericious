=head1 NAME

Clustericious::Command::Lighttpd

=head1 DESCRIPTION

Start a lighttpd web server.

=cut

package Clustericious::Command::Lighttpd;
use Clustericious::Log;

use Clustericious::App;
use Clustericious::Config;
use base 'Mojo::Command';

use strict;
use warnings;

__PACKAGE__->attr(description => <<EOT);
Start a lighttpd web server.
EOT

__PACKAGE__->attr(usage => <<EOT);
Usage $0: lighttpd -f <config file> [...other lighttpd options]
Starts a lighttpd webserver.
Options are passed verbatim to the lighttpd executable.
EOT

sub run {
    my $self = shift;
    my @args = @_ ? @_ : @ARGV;
    my $app_name = $ENV{MOJO_APP};

    # Clustericious::App->init_logging;

    my $lighttpd = qx[which lighttpd] or LOGDIE "could not find lighttpd in $ENV{PATH}";
    chomp $lighttpd;
    DEBUG "starting $lighttpd @args";
    system( $lighttpd, @args ) == 0
      or die "could not start $lighttpd @args ($?) "
      . ( ${^CHILD_ERROR_NATIVE} || '' );
}

1;


