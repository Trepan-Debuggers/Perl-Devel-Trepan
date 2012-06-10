#!/usr/bin/env perl
use strict; use warnings; no warnings 'redefine';
use rlib '../lib';
use vars qw(@args); 

use Test::More;

BEGIN {
note( "Testing Devel::Trepan::CmdProcessor::Hook" );
use_ok( 'Devel::Trepan::CmdProcessor::Hook' );
}

@args = ();
my $hook1 = sub { 
    my ($name, $a) = @_;
    push @args, $name;
};

my $hooks = Devel::Trepan::CmdProcessor::Hook->new();
is(scalar(@{$hooks->{list}}), 0, "Initialized hooks should have empty list");
$hooks->insert(-1, 'hook1', $hook1);
is(scalar(@{$hooks->{list}}), 1, "hooks should have 1 item");
$hooks->run;
is (scalar @args, 1);
is ($args[0], 'hook1');
$hooks->insert_if_new(-1, 'hook1', $hook1);
is(scalar(@{$hooks->{list}}), 1, "hooks should still have 1 item");
@args = ();
$hooks->insert_if_new(-1, 'hook2', $hook1);
$hooks->run;
is (scalar @args, 2);
is ($args[0], 'hook2');
is ($args[1], 'hook1');

done_testing();
