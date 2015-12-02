#!/usr/bin/env perl
use strict; use warnings;
no warnings 'redefine'; no warnings 'once';
use rlib '../lib';

use Test::More;
note( "Testing Devel::CmdProcessor::Command::Break and Clear" );

BEGIN {
    use_ok( 'Devel::Trepan::CmdProcessor::Command::Break' );
    use_ok( 'Devel::Trepan::CmdProcessor::Command::Clear' );
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

my $err_msg = '';
my $msg = '';

require Devel::Trepan::CmdProcessor;

# monkeypatch errmsg
local *Devel::Trepan::CmdProcessor::errmsg = sub {
    my ($self, $msg) = @_;
    print "@{$msg}\n";
    $err_msg = $msg->[0];
};

# monkeypatch msg
local *Devel::Trepan::CmdProcessor::msg = sub {
    my ($self, $msg) = @_;
    print "@{$msg}\n";
    $msg = $msg->[0];
};

my $counter = 1;
my $dbgr = Devel::Trepan::Core->new();
my $proc = Devel::Trepan::CmdProcessor->new(undef, $dbgr);
$proc->{stack_size} = 0;

my $clear_cmd = Devel::Trepan::CmdProcessor::Command::Clear->new($proc);
my $break_cmd = Devel::Trepan::CmdProcessor::Command::Break->new($proc);

note "Clear when there is nothing to clear";

$proc->{frame} = {line => 1};
$err_msg = '';
$clear_cmd->run(['clear']);
is($err_msg, "No breakpoint at line 1");
$clear_cmd->run(['clear', 4]);
is($err_msg, "No breakpoint at line 4");
$err_msg = '';

note("no arg");
$break_cmd->run(['break']);
is($main::break_args[1], '');
my $line = __LINE__;
$proc->{frame} = {line => $line};

$break_cmd->run(['break', __FILE__, $line]);

is($main::break_args[5], $line);

# Should run okay
$break_cmd->run(['clear', $line]);
is($err_msg, '', 'clear a set breakpoint');

done_testing();
