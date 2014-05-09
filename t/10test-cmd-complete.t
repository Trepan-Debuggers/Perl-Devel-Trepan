#!/usr/bin/env perl
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
my $counter = 1;
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

for my $tuple (['b',  2],
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
is(scalar(@msgs), 2, "Should have 2 completions for '$prefix'");

# Completion of 'info' should be 'info'
$prefix = 'info';
$cmd->{proc}{cmd_argstr} = $prefix;
@msgs = ();
$cmd->run([$cmd->name, $prefix]);
is(scalar(@msgs), 1,
   "Should have only gotten one completion back for '$prefix'");
is($msgs[0], $prefix, "Completion of '$prefix' should be $prefix'");

# Completion of 'info ' should contain subcommands of
# 'info'
$prefix = 'info ';
$cmd->{proc}{cmd_argstr} = $prefix;
@msgs = ();
$cmd->run([$cmd->name, $prefix]);
ok(scalar(@msgs) > 1);

# Completion of 'info f' is ['info files', 'info frame', 'info functions']
$prefix = 'info f';
$cmd->{proc}{cmd_argstr} = $prefix;
@msgs = ();
$cmd->run([$cmd->name, $prefix]);
my @expect = qw(files frame functions);
is(scalar(@msgs), scalar @expect);
for (my $i=0; $i < scalar @expect; $i++) {
    is($msgs[$i], $expect[$i],
       "Expecting completion $i of '$prefix' to be '${expect[$i]}'");
}

# Completion of 'help syntax c' is ['command']
$prefix = 'help syntax c';
$cmd->{proc}{cmd_argstr} = $prefix;
@msgs = ();
$cmd->run([$cmd->name, $prefix]);
@expect = qw(command);
is(scalar(@msgs), scalar @expect);
for (my $i=0; $i < scalar @expect; $i++) {
    is($msgs[$i], $expect[$i],
       "Expecting completion $i of '$prefix' to be '${expect[$i]}'");
}


foreach my $tuple (
    ['CORE::len', ['CORE::length']],
    ['len', ['length']],
    ['db', ['dbmclose', 'dbmopen']],
    ['foo', []],
    ['CORE::foo', []]
    ) {
    my ($prefix, $array) = @{$tuple};
    my @got = Devel::Trepan::Complete::complete_builtin($prefix);
    is_deeply(\@got, $array);
}

$DB::package = 'main';
%DB::sub = qw(main::gcd 1);
foreach my $tuple (
    ['end',
     ['endgrent', 'endhostent', 'endnetent', 'endprotoent',
      'endpwent', 'endservent']],
    ['CORE::endp',
     ['CORE::endprotoent', 'CORE::endpwent']],
    ['gcd', ['gcd']],
    ['main::gcd', ['main::gcd']],
    ['__FI', ['__FILE__']],
    ['__LI', ['__LINE__']],
    ['__P',  ['__PACKAGE__']],
    ['foo', []]) {
    my ($prefix, $array) = @{$tuple};
    my @got = Devel::Trepan::Complete::complete_function($prefix);
    is_deeply(\@got, $array);
}


done_testing();
