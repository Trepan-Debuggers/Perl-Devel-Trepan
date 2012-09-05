#!/usr/bin/env perl
use strict; use warnings; 
no warnings 'redefine'; no warnings 'once';
use rlib '../lib';

use Test::More;
note( "Testing Devel::CmdProcessor::Command::Macro" );

BEGIN {
    use_ok( 'Devel::Trepan::CmdProcessor::Command::Macro' );
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
my $proc = Devel::Trepan::CmdProcessor->new(undef, 'bogus');
monkey_patch_instance($proc, 
		      msg => sub { my($self, $message, $opts) = @_;
				   push @msgs, $message;
				   });

my $cmd = Devel::Trepan::CmdProcessor::Command::Macro->new($proc);

$proc->{cmd_argstr} = "fin+ sub{ ['finish', 'step']}";
my @args = ('macro', split(/\s+/, $proc->{cmd_argstr}));
$cmd->run(\@args);    

is(scalar @{$proc->{macros}{'fin+'}}, 2);
is(ref $proc->{macros}{'fin+'}[0], 'CODE');
my $str = $proc->{macros}{'fin+'}[1];
is($str, "sub{ ['finish', 'step']}");

done_testing();
