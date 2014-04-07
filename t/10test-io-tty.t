#!/usr/bin/env perl
use strict; use warnings;
use English qw( -no_match_vars );
use rlib '../lib';
use Config;

use Test::More;
if ($OSNAME eq 'MSWin32' or $OSNAME eq 'msys') {
    plan skip_all => 'FIXME make work on MinGW and Strawberry Perl?'
} else {
    plan ;
}

note( "Testing Devel::IO::FIFOServer" );

require_ok( 'Devel::Trepan::IO::TTYServer' );
require_ok( 'Devel::Trepan::IO::TTYClient' );

# FIXME: This test is based on TTYServer.
# do a second test here based on IO/TTYClient.

note "Testing TTY server open";
my $server = Devel::Trepan::IO::TTYServer->new({open => 1, logger=>undef});
ok($server, "TTYServer open");
my $pid = fork();
if ($pid) {
    note "$$: server before write";
    $server->writeline("server to client");
    note "$$: server before read";
    my $msg = $server->read_msg();
    ok($msg,  "$$: client read from server");
    note "server before second write\n";
    $server->write("server to client nocr");
    note "$$: Server is done but waiting on client";
    waitpid($pid, 0);
    is($? >> 8, 0, "$$: child $pid terminates normally");
    $server->close();
    note "Server $$ is leaving";
    done_testing(5);
} else {
    # Client's input goes to server's output and vice versa
    my $client = Devel::Trepan::IO::TTYClient->new(
	{'open'=> 1,
	 'input'  => $server->{output}->slave,
	 'output' => $server->{input}->slave,
	});
    # ok($client, "$$: TTYClient open");
    note "$$: client before read\n";
    my $msg = $client->read_msg();
    #ok($msg, "$$: Client read from server message");
    $client->writeline("client to server ($$)");
    note "$$: client before second read";
    $msg = $client->read_msg();
    # ok($msg, "$$: Client read (nocr) from server message");
    note "$$: Client is leaving";
    $client->close();
    done_testing(-2); # Not sure why -2?
}
