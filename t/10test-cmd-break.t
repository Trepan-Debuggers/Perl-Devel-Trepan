#!/usr/bin/env perl
use strict; use warnings;
no warnings 'redefine'; no warnings 'once';
use rlib '../lib';

use Test::More;
note( "Testing Devel::CmdProcessor::Command::Break" );

BEGIN {
    use_ok( 'Devel::Trepan::CmdProcessor::Command::Break' );
}

use vars qw(@break_args);
@break_args = ();

package Devel::Trepan::Core;
sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
}

sub set_break {
    push @main::break_args, @_;
    return undef;
}

sub subs {
    return undef;
}

sub break_invalid {
    return undef;
}

package main;

require Devel::Trepan::CmdProcessor;

# Monkey::Patch doesn't work with methods with prototypes;
my $counter = 1;
my $dbgr = Devel::Trepan::Core->new();
my $proc = Devel::Trepan::CmdProcessor->new(undef, $dbgr);
my $cmd = Devel::Trepan::CmdProcessor::Command::Break->new($proc);

my @args = ('break');
$cmd->run(\@args);
is($main::break_args[1], '');
my $line = __LINE__;
@args = ('break', __FILE__, $line);
$cmd->run(\@args);
is($main::break_args[5], $line);

done_testing();
