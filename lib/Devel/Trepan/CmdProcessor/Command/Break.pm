# -*- coding: utf-8 -*-
# Copyright (C) 2011-2014 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';
use rlib '../../../..';

use Devel::Trepan::DB::Sub;
# require_relative '../../app/condition'

package Devel::Trepan::CmdProcessor::Command::Break;
use Devel::Trepan::DB::LineCache;
use English qw( -no_match_vars );
use if !@ISA, Devel::Trepan::CmdProcessor::Command;
unless (@ISA) {
    eval <<'EOE';
    use constant ALIASES    => qw(b);
    use constant CATEGORY   => 'breakpoints';
    use constant SHORT_HELP => 'Set a breakpoint';
    use constant MIN_ARGS  => 0;   # Need at least this many
    use constant MAX_ARGS  => undef;  # Need at most this many - undef -> unlimited.
    use constant NEED_STACK => 0;
EOE
}

use strict; use vars qw(@ISA); @ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
=pod

=head2 Synopsis:

=cut
our $HELP = <<'HELP';
=pod

B<break> [I<location>] [B<if> I<condition>]

Set a breakpoint. If I<location> is given use the current stopping
point. An optional condition may be given.

=head2 Examples:

 break                  # set a breakpoint on the current line
 break gcd              # set a breakpoint in function gcd
 break gcd if $a == 1   # set a breakpoint in function gcd with
                        # condition $a == 1
 break 10               # set breakpoint on line 10

When a breakpoint is hit the event icon is C<xx>.

=head2 See also:

C<help breakpoints>, L<C<info
breakpoints>|Devel::Trepan::CmdProcessor::Command::Info::Breakpoints>,
and L<C<help syntax location>|Devel::Trepan::CmdProcessor::Command::Help::location>.

=cut
HELP

# FIXME: Should we include all files?
# Combine with LIST completion.
sub complete($$)
{
    my ($self, $prefix) = @_;
    my $filename = $self->{proc}->filename;
    my @completions = sort(('.', file_list, DB::subs,
                            trace_line_numbers($filename)));
    Devel::Trepan::Complete::complete_token(\@completions, $prefix);
}

#  include Trepan::Condition

# This method runs the command
sub run($$) {
    my ($self, $args) = @_;
    my @args = @$args;
    shift @args;
    my $proc = $self->{proc};
    my $bp;
    my $arg_count = scalar @args;
    if ($arg_count == 0) {
        $bp = $self->{dbgr}->set_break($DB::filename, $DB::lineno);
    } else {
        my ($filename, $line_or_fn, $condition);
        if ($arg_count > 2) {
            if ($args[0] eq 'if') {
                $line_or_fn = $DB::lineno;
                $filename = $DB::filename;
                unshift @args, $line_or_fn;
            } else  {
                $filename = $args[0];
                if ($args[1] =~ /\d+/) {
                    $line_or_fn = $args[1];
                    shift @args;
                } elsif ($args[1] eq 'if') {
                    $line_or_fn = $args[0];
                } else {
                    $line_or_fn = $args[0];
                }
            }
        } else {
            # $arg_count <= 2.
            $line_or_fn = $args[0];
            if ($line_or_fn =~ /^\d+/) {
                $filename = $DB::filename;
            } else {
                my @matches = $self->{dbgr}->subs($args[0]);
                if (scalar(@matches) == 1) {
                    $filename = $matches[0][0];
                } else {
		    $filename = $args[0];
                    my $canonic_name = map_file($filename);
                    if (is_cached($canonic_name)) {
                        $filename = $canonic_name;
                    }
                }
            }
            if ($arg_count == 2 && $args[1] =~ /\d+/) {
                $line_or_fn = $args[1];
                shift @args;
            }
        }
        shift @args;
        if (scalar @args) {
            if ($args[0] eq 'if') {
                shift @args;
                $condition = join(' ', @args);
            } else {
                $proc->errmsg("Expecting 'if' to start breakpoint condition;" .
                              " got ${args[0]}");
            }
        }
        my $msg = $self->{dbgr}->break_invalid(\$filename, $line_or_fn);
        my $force = 0;
        if ($msg) {
            if ($msg =~ /not known to be a trace line/) {
                $proc->errmsg($msg);
                $proc->msg("Use 'info file $filename brkpts' to see breakpoints I know about");
                $force = $self->{proc}->confirm('Set breakpoint anyway?', 0);
                return unless $force;
            }
        }
        $bp = $self->{dbgr}->set_break($filename, $line_or_fn,
                                       $condition, undef, undef, undef, $force);
    }
    if (defined($bp)) {
            my $prefix = $bp->type eq 'tbrkpt' ?
                'Temporary breakpoint' : 'Breakpoint' ;
            my $id = $bp->id;
            my $filename = $proc->canonic_file($bp->filename);
            my $line_num = $bp->line_num;
            $proc->{brkpts}->add($bp);
            $proc->msg("$prefix $id set in $filename at line $line_num");
            # Warn if we are setting a breakpoint on a line that starts
            # "use.."
            my $text = getline($bp->filename, $line_num, {output => 'plain'});
            if (defined($text) && $text =~ /^\s*use\s+/) {
                $proc->msg("Warning: 'use' statements get evaluated at compile time... You may have already passed this statement.");
            }
    }
}

unless (caller) {
    # FIXME: DRY this code by putting in common location.
    require Devel::Trepan::DB;
    require Devel::Trepan::Core;
    my $db = Devel::Trepan::Core->new;
    my $intf = Devel::Trepan::Interface::User->new(undef, undef,
                                                   {readline => 0});
    my $proc = Devel::Trepan::CmdProcessor->new([$intf], $db);
    $proc->{stack_size} = 0;
    my $cmd = __PACKAGE__->new($proc);

    eval {
      sub db_setup() {
          no warnings 'once';
          $DB::caller = [caller];
          ($DB::package, $DB::filename, $DB::lineno, $DB::subroutine)
              = @{$DB::caller};
      }
    };
    db_setup();

    $cmd->run([$NAME]);
    # $cmd->run([$NAME, "/usr/share/perl/5.14.2/File/Basename.pm", "3"]);
}

1;
