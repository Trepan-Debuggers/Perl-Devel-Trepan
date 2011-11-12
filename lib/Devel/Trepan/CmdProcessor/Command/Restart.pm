# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
# Code adapted from Perl 5's perl5db.pl
# -*- coding: utf-8 -*-
use warnings; no warnings 'redefine';
use rlib '../../../..';

package Devel::Trepan::CmdProcessor::Command::Restart;
use English qw( -no_match_vars );

use if !defined @ISA, Devel::Trepan::CmdProcessor::Command ;
unless (defined(@ISA)) {
    eval "use constant CATEGORY   => 'running';";
    eval "use constant SHORT_HELP => '(Hard) restart of program via exec()'";
}

use strict;
use vars qw(@ISA);
@ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

our $MIN_ARGS = 0;
our $MAX_ARGS = undef;
our $NAME = set_name();
our $HELP = <<"HELP";
$NAME 

Restart debugger and program via an exec call.
HELP

use constant ALIASES  => ('R');
  
# This method runs the command
sub run($$) {
    my ($self, $args) = @_;

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

    # If this was a perl one-liner, go to the "file"
    # corresponding to the one-liner read all the lines
    # out of it (except for the first one, which is going
    # to be added back on again when 'perl -d' runs: that's
    # the 'require perl5db.pl;' line), and add them back on
    # to the command line to be executed.
    if ( $0 eq '-e' ) {
        for ( 1 .. $#{'::_<-e'} ) {  # The first line is PERL5DB
            chomp( $cl = ${'::_<-e'}[$_] );
            push @script, '-e', $cl;
        }
    } ## end if ($0 eq '-e')

    # Otherwise we just reuse the original name we had
    # before.
    else {
	@script = ($EXECUTABLE_NAME, @flags, '-d:Trepan', $DB::ini_dollar0, @DB::ini_ARGV);
	# print "Running: ", join(', ', @script, "\n");
        # @script = ($0);
    }

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
