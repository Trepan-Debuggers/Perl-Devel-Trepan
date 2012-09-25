#!/usr/bin/env perl
use strict;
use warnings;
use rlib '../lib';

use Test::More;
note( "Testing Devel::IO::TCPServer" );

BEGIN {
    use_ok( 'Devel::Trepan::IO::TCPServer' );
}

note "Testing failure to open server port";
my $pid = fork();
if ($pid == 0) {
    my $connection_opts = {
        io => 'TCP',
        port => 80,  # It's
        logger => undef  # An Interface. Complaints go here.
    };
    my $inout = Devel::Trepan::IO::TCPServer->new($connection_opts);
    my $rc = $? >> 8;
    unless ($rc) {
        # Can't use the same port twice.
        diag("foo");
        my $inout2 = Devel::Trepan::IO::TCPServer->new($connection_opts);
        $rc = $? >> 8;
    }
    exit $rc;
} else {
    waitpid($pid, 0);
    isnt($?>>8, 0);
}

done_testing();
