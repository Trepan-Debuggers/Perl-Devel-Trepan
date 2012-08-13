# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
# Code adapted from Perl 5's perl5db.pl
# -*- coding: utf-8 -*-
use warnings; no warnings 'redefine';
use rlib '../../../..';

package Devel::Trepan::CmdProcessor::Command::Restart;
use English qw( -no_match_vars );

use if !@ISA, Devel::Trepan::CmdProcessor::Command ;
unless (@ISA) {
    eval <<'EOE';
use constant ALIASES    => ('R');
use constant CATEGORY   => 'running';;
use constant SHORT_HELP => '(Hard) restart of program via exec()';
use constant MIN_ARGS   => 0;     # Need at least this many
use constant MAX_ARGS   => undef; # Need at most this many - undef -> unlimited.
EOE
}

use strict;
use vars qw(@ISA);
@ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
our $HELP = <<"HELP";
$NAME 

Restart debugger and program via an exec call.
HELP

# This method runs the command
sub run($$) {
    my ($self, $args) = @_;
    my $dbgr = $self->{proc}{dbgr};

    # I may not be able to resurrect you, but here goes ...
    $self->msg("Warning: some settings and command-line options may be lost!");

    my ( @script, @flags, $cl );
    # If warn was on before, turn it on again.
    no warnings 'once';
    push @flags, '-w' if $DB::ini_warn;

    # Rebuild the -I flags that were on the initial
    # command line.
    for (@DB::ini_INC) {
        push @flags, '-I', $_;
    }

    # Turn on taint if it was on before.
    push @flags, '-T' if ${^TAINT};

    # Arrange for setting the old INC:
    # Save the current @init_INC in the environment.
    DB::set_list( "PERLDB_INC", @DB::ini_INC );

    @script = ($EXECUTABLE_NAME, @flags, '-d:Trepan', $DB::ini_dollar0, 
	       @{$dbgr->{exec_strs}},
	       @DB::ini_ARGV);
    # print "Running: ", join(', ', @script, "\n");
    # @script = ($0);

    # And run Perl again.  We use exec() to keep the
    # PID stable (and that way $ini_pids is still valid).
    exec(@script) || $self->errmsg("exec failed: $!");

}

unless (caller()) {
    require Devel::Trepan::CmdProcessor::Mock;
    my $proc = Devel::Trepan::CmdProcessor::Mock::setup();
    my $cmd = Devel::Trepan::CmdProcessor::Command::Restart->new($proc);
}

1;
