use strict;
use warnings;
use Test::Clustericious::Command;
use Test::More;
use Clustericious::HelloWorld::Client;

plan skip_all => 'test leaves processes running';

requires 'lighttpd.conf', 11;
extract_data;
mirror 'example/etc' => 'etc';

$ENV{CLUSTERICIOUS_TEST_PORT} = generate_port;

my $client = Clustericious::HelloWorld::Client->new;

run_ok('hello', 'status')
  ->exit_is(2)
  ->note;

run_ok('hello', 'start')
  ->exit_is(0)
  ->note;

run_ok('hello', 'status')
  ->exit_is(0)
  ->note;

is $client->welcome, 'Hello, world', 'client connects okay.';

run_ok('hello', 'stop')
  ->exit_is(0)
  ->note;

run_ok('hello', 'status')
  ->exit_is(2)
  ->note;

__DATA__

@@ bin/hello
#!/usr/bin/perl

use strict;
use warnings;
use Clustericious::Commands;
$ENV{MOJO_APP} = 'Clustericious::HelloWorld';
Clustericious::Commands->start;

@@ etc/Clustericious-HelloWorld.conf
---
% extends_config 'lighttpd', host => $ENV{CLUSTERICIOUS_TEST_HOST}, port => $ENV{CLUSTERICIOUS_TEST_PORT};
