#!/usr/bin/env perl
use feature ":5.10";  # Includes "state" feature.
use strict; use warnings; 
no warnings 'redefine'; no warnings 'once';
use rlib '../lib';

use Test::More;
note( "Testing Devel::CmdProcessor::Command::Complete" );

BEGIN {
    use_ok( 'Devel::Trepan::CmdProcessor::Command::Complete' );
}

require Devel::Trepan::CmdProcessor;

# Monkey::Patch doesn't work with methods with prototypes;
state $counter = 1;
sub monkey_patch_instance
{
    my($instance, $method, $code) = @_;
    my $package = ref($instance) . '::MonkeyPatch' . $counter++;
    no strict 'refs';
    @{$package . '::ISA'} = (ref($instance));
    *{$package . '::' . $method} = $code;
    bless $_[0], $package; # sneaky re-bless of aliased argument
}

my @msgs = ();
my $cmdproc = Devel::Trepan::CmdProcessor->new;
monkey_patch_instance($cmdproc, 
		      msg => sub { my($self, $message, $opts) = @_;
				   push @msgs, $message;
				   });
my $cmd = Devel::Trepan::CmdProcessor::Command::Complete->new($cmdproc);

for my $tuple (['d',  6],
	       ['b',  2],
	       ['bt', 1]) {
    my ($prefix, $expected) = @{$tuple};
    $cmd->{proc}{cmd_argstr} = $prefix;
    @msgs = ();
    $cmd->run([$cmd->name, $prefix]);
    is(scalar(@msgs), $expected);
}

my $prefix = 'set a';
$cmd->{proc}{cmd_argstr} = $prefix;
@msgs = ();
$cmd->run([$cmd->name, $prefix]);
is(scalar(@msgs), 2);

# Completion of 'info' should be 'info'
$prefix = 'info';
$cmd->{proc}{cmd_argstr} = $prefix;
@msgs = ();
$cmd->run([$cmd->name, $prefix]);
is(scalar(@msgs), 1);
is($msgs[0], 'info');

# Completion of 'info ' should contain subcommands of 
# 'info'
$prefix = 'info ';
$cmd->{proc}{cmd_argstr} = $prefix;
@msgs = ();
$cmd->run([$cmd->name, $prefix]);
ok(scalar(@msgs) > 1);

# Completion of 'info f' is ['info files', 'info frame']
$prefix = 'info f';
$cmd->{proc}{cmd_argstr} = $prefix;
@msgs = ();
$cmd->run([$cmd->name, $prefix]);
is(scalar(@msgs), 3);
is($msgs[0], 'files');
is($msgs[1], 'frame');
is($msgs[2], 'functions');

done_testing();
