package Clustericious::Command::Generate;

use strict;
use warnings;

use base 'Mojolicious::Command::Generate';

__PACKAGE__->attr(namespaces =>
      sub { [qw/Clustericious::Command::Generate
                Mojolicious::Command::Generate
                Mojo::Command::Generate/] });

1;
