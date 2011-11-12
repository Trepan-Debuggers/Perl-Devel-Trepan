# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';
use feature 'switch';
use rlib '../../../..';

package Devel::Trepan::CmdProcessor::Command::Edit;
use if !defined @ISA, Devel::Trepan::CmdProcessor::Command ;
use strict;

use vars qw(@ISA); @ISA = @CMD_ISA; 
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
our $HELP = <<"HELP";
${NAME} [[FILE] [LINE]]

With no argument, edits file containing most recent line listed.
The value of the environment variable EDITOR is used for the
editor to run. If no EDITOR environment variable is set /bin/ex
is used. The editor should support line and file positioning via
   editor-name +line file-name
(Most editors do.)

Examples:
${NAME}            # Edit current location
${NAME} 7          # Edit current file at line 7
${NAME} test.rb    # Edit test.rb, line 1
${NAME} test.rb 10 # Edit test.rb  line 10
HELP

use constant ALIASES    => ('e');
use constant CATEGORY   => 'files';
use constant SHORT_HELP => 'Invoke an editor on some source code';
our $NEED_STACK   = 0;
our $MAX_ARGS     = 2;  # Need at most this many


# This method runs the command
sub run($$)
{
    my ($self, $args) = @_;
    my ($filename, $line_number);
    given (scalar @$args) {
	when (1) {
	    $filename     = $self->{proc}{frame}{file};
	    $line_number  = $self->{proc}{frame}{line};
	} when(2) {
	    $line_number = $self->{proc}->get_int_noerr($args->[1]);
	    if (defined $line_number) {
		$filename = $self->{proc}{frame}{file};
	    } else {
		$filename = $args->[1];
		$line_number = 1;
	    }
	} when (3) {
	    ($line_number, $filename) =  ($args->[2], $args->[1]);
	} default {
	    $self->errmsg("edit needs at most 2 args.");
	}
    }
    my $editor = $ENV{'EDITOR'} || '/bin/ex';
    if ( -r $filename ) {
	use File::Basename;
	$filename = basename($filename) if $self->{proc}{settings}{basename};
	my @edit_cmd = ($editor, "+$line_number", $filename);
	$self->{proc}->msg(sprintf "Running: %s...", join(' ', @edit_cmd));
	system(@edit_cmd);
	$self->{proc}->msg("Warning: return code was $?") if $? != 0;
    } else {
	$self->errmsg("File \"${filename}\" is not readable.");
    }
}

unless (caller) {
    require Devel::Trepan::CmdProcessor;
    my $proc = Devel::Trepan::CmdProcessor->new(undef, 'bogus');
    my $cmd = __PACKAGE__->new($proc);
    $cmd->run([$NAME]);
    $cmd->run([$NAME, '7']);
    $cmd->run([$NAME, __FILE__, '10']);
}

1;
