# -*- coding: utf-8 -*-
# Copyright (C) 2011-2012, 2014 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';
use rlib '../../../..';

# require_relative '../../app/condition'

package Devel::Trepan::CmdProcessor::Command::List;
use English qw( -no_match_vars );
use Devel::Trepan::DB::LineCache;
use Devel::Trepan::CmdProcessor::Validate;
use if !@ISA, Devel::Trepan::CmdProcessor::Command;
unless (@ISA) {
    eval <<'EOE';
    use constant ALIASES    => qw(l list> l>);
    use constant CATEGORY   => 'files';
    use constant SHORT_HELP => 'List source code';
    use constant MIN_ARGS   => 0; # Need at least this many
    use constant MAX_ARGS   => 3; # Need at most this many - undef -> unlimited.
    use constant NEED_STACK => 0;
EOE
}

use strict; use vars qw(@ISA); @ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
=head2 Synopsis:

=cut
our $HELP = <<'HELP';
=pod

B<list>[E<gt>] [I<filename>] [I<first> [I<number>]]

B<list>[E<gt>] I<location> [I<number>]

List Perl source code.

Without arguments, prints lines centered around the current
line. If this is the first list command issued since the debugger
command loop was entered, then the current line is the current
frame. If a subsequent list command was issued with no intervening
frame changing, then that is start the line after we last one
previously shown.

If the command has a '>' suffix, then line centering is disabled and
listing begins at the specificed location.

The number of lines to show is controlled by the debugger "listsize"
setting. Use L<C<set max
list>|Devel::Trepan::CmdProcessor::Set::Max::List> or C<show max list>
to see or set the value.

If the location form is used with a subsequent parameter, the
parameter is the starting line number.  When there two numbers are
given, the last number value is treated as a stopping line unless it
is less than the start line, in which case it is taken to mean the
number of lines to list instead.

=head2 Examples:

 list 5            # List centered around line 5
 list 5>           # List starting at line 5
 list foo.pl 5     # Same as above.
 list foo.pl  5 6  # list lines 5 and 6 of foo.pl
 list foo.pl  5 2  # Same as above, since 2 < 5.
 list .            # List lines centered from where we currently are stopped
 list . 3          # List 3 lines starting from where we currently are stopped
                     # if . > 3. Otherwise we list from . to 3.
 list -            # List lines previous to those just shown

The output of the list command give a line number, and some status
information about the line and the text of the line. Here is some
hypothetical list output modeled roughly around line 251 of one
version of this code:

  251             cmd.proc.frame_setup(tf)
  252  ->         brkpt_cmd.run(['break'])
  253 B01         line = __LINE__
  254 b02         cmd.run(['list', __LINE__.to_s])
  255 t03         puts '--' * 10

Line 251 has nothing special about it. Line 252 is where we are
currently stopped. On line 253 there is a breakpoint 1 which is
enabled, while at line 255 there is an breakpoint 2 which is
disabled.

=head2 See also:

L<C<set
autolist>|Devel::Trepan::CmdProcessor::Command::Set::Auto::List>,
L<C<help syntax
location>|Devel::Trepan::CmdProcessor::Command::Help::location>, and
C<deparse>|Devel::Trepan::CmdProcessor::Command::Deparse>.

=cut
HELP

# FIXME: Should we include all files?
# Combine with BREAK completion.
sub complete($$)
{
    my ($self, $prefix) = @_;
    my $filename = $self->{proc}->filename;
    # For line numbers we'll use stoppable line number even though one
    # can enter line numbers that don't have breakpoints associated with them
    my @completions = sort(('.', '-', file_list, DB::subs(),
                            trace_line_numbers($filename)));
    Devel::Trepan::Complete::complete_token(\@completions, $prefix);
}

# If last is less than first, assume last is a count rather than an
# end line number.
sub adjust_end($$)
{
    my ($start, $end) = @_;
    return ($start < $end ) ? $start + $end - 1 : $end;
}

sub no_frame_msg($)
{
    my $self = shift;
    $self->errmsg("No Perl program loaded.");
    return (undef, undef, undef);
}


# What a mess. Necessitated I suppose because we want to allow
# somewhat flexible parsing with either module names, files or none
# and optional line counts or end-line numbers.
# TODO: allow a negative start to count from the end of the file.

# Parses arguments for the "list" command and returns the tuple:
# filename, start, last
# or sets these to nil if there was some problem.
sub parse_list_cmd($$$$)
{
    my ($self, $args, $listsize, $center_correction) = @_;
    my $proc = $self->{proc};
    my $frame = $proc->{frame};
    my @args = @$args;
    shift @args;

    my $filename = $proc->{list_filename};
    my $fn;
    my ($start, $end);

    if (scalar @args  > 0) {
        if ($args[0] eq '-') {
            return $self->no_frame_msg() unless $proc->{list_line};
            $start = $proc->{list_line} - 2*$listsize;
            $start = 1 if $start < 1;
        } elsif ($args[0] eq '.') {
            return $self->no_frame_msg() unless $frame->{line};
            $filename = $proc->filename;
            $start    = $proc->line;
            $start    = 1 if $start < 1;
            if (scalar @args == 2) {
                my $opts = {
                    'msg_on_error' =>
                        "${NAME} command $end or count parameter expected, " .
                        "got: $args[2]"
                };
                my $second = $proc->get_an_int($args[1], $opts);
                return (undef, undef, undef) unless $second;
                $end = $self->adjust_end($start, $second);
            }
        } else {
            my ($rest, $gobble_count);
            ($filename, $start, $fn, $gobble_count, $rest) = $proc->parse_position(\@args);
            return (undef, undef, undef) unless defined $start;
            shift @args if $gobble_count > 0;
            # error should have been shown previously
        }
        if (scalar @args <= 1) {
            $start = 1 if !$start and $fn;
            $start = $start - $center_correction;
            $start = 1 if $start < 1;
        } elsif (scalar @args == 2 or (scalar @args == 3 and $fn)) {
            my $opts = {
                msg_on_error =>
                    "${NAME} command starting line expected, got $args[-1]"
            };
            $end = $proc->get_an_int($args[1], $opts);
            return (undef, undef, undef) unless $end;
            if ($fn) {
                if ($start) {
                    $start = $end;
                    if (scalar @args == 3 and $fn) {
                        my $opts = {
                            'msg_on_error' =>
                            ("${NAME} command $end or count parameter expected, " .
                             "got: ${$args[2]}.")};
                        $end = $proc->get_an_int($args[2], $opts);
                        return (undef, undef, undef) unless $end;
                    }
                }
            }
            $end = $self->adjust_end($start, $end);
        } elsif (! $fn) {
            $proc->errmsg('At most 2 parameters allowed when no module' .
                          " name is found/given. Saw: @args parameters");
            return (undef, undef, undef);
        } else {
            $proc->errmsg('At most 3 parameters allowed when a module' +
                          " name is given. Saw: @args parameters");
            return (undef, undef, undef);
        }
    } elsif ($frame && !$frame->{line} and $proc->{frame}) {
        $start = $frame->{line} - $center_correction;
    }  else {
        $start = ($proc->{list_line} || $frame->{line}) - $center_correction;
    }
    $start = 1 if $start < 1;
    $end = $start + $listsize - 1 unless $end;

    cache_file($filename) unless is_cached($filename);
    return ($filename, $start, $end);
}

# This method runs the command
sub run($$)
{
    my ($self, $args) = @_;
    my $proc = $self->{proc};

    my $listsize = $proc->{settings}{maxlist};
    my $center_correction =
        (substr($args->[0], -1, 1) eq '>') ? 0 : int(($listsize-1) / 2);

    my ($filename, $start, $end) = parse_list_cmd($self, $args, $listsize,
                                                  $center_correction);
    return unless $filename;

    # We now have range information. Do the listing.
    my $max_line = Devel::Trepan::DB::LineCache::size($filename);
    $filename = map_file($filename);
    unless (defined $max_line) {
        $proc->errmsg("File \"$filename\" not found.");
        return;
    }

    if ($start > $max_line) {
        my $mess = sprintf('Bad line range [%d...%d]; file "%s" has only %d lines',
                           $start, $end, $proc->canonic_file($filename), $max_line);
        $proc->errmsg($mess);
        return;
    }

    if ($end > $max_line) {
        # msg('End position changed to end line %d ' % max_line)
        $end = $max_line;
    }

    #   begin
    my $opts = {
        reload_on_change => $proc->{settings}{reload},
        output           => $proc->{settings}{highlight}
    };
    my $bp;
    local(*DB::dbline) = "::_<$filename";
    my $lineno;
    my $msg = sprintf("%s [%d-%d]", $proc->canonic_file($filename), $start, $end);

    # FIXME: put in frame?
    my $frame_filename = $proc->filename();
    $frame_filename = map_file($frame_filename)
	if filename_is_eval($frame_filename);

    $self->section($msg);
    for ($lineno = $start; $lineno <= $end; $lineno++) {
        my $a_pad = '  ';
        my $line  = getline($filename, $lineno, $opts);
        unless (defined $line) {
            if ($lineno > $max_line)  {
                $proc->msg('[EOF]');
                last;
            } else {
                $line = '';
            }
        }
        chomp $line;
        my $s = sprintf('%3d', $lineno);
        $s = $s . ' ' if length($s) < 4;

	## FIXME: move into DB::Breakpoint and adjust List.pm
        if (exists($DB::dbline{$lineno}) and
            my $brkpts = $DB::dbline{$lineno}) {
            my $found = 0;
            for my $bp (@{$brkpts}) {
                if (defined($bp)) {
                    $a_pad = sprintf('%02d', $bp->id);
                    $s .= $bp->icon_char;
                    $found = 1;
                    last;
                }
            }
            $s .= ' ' unless $found;
        } else  {
            $s .= ' ';
        }
	## FIXME move above code

        $s .= ($proc->{frame} && $lineno == $proc->line &&
               $frame_filename eq $filename) ? '->' : $a_pad;
        my $opts = {unlimited => 1};
        $proc->msg("$s\t$line", $opts);
    }
    $proc->{list_line} = $lineno + $center_correction;
    $proc->{list_filename} = $filename;
  #   rescue => e
  #     errmsg e.to_s if settings[:debugexcept]
  #   end
}

unless (caller) {
    require Devel::Trepan::CmdProcessor::Mock;
    my $proc = Devel::Trepan::CmdProcessor->new(undef, 'bogus');
    my $cmd = __PACKAGE__->new($proc);
    require Devel::Trepan::DB::Sub;
    require Devel::Trepan::DB::LineCache;
    cache_file(__FILE__);
    my $frame_ary = Devel::Trepan::CmdProcessor::Mock::create_frame();
    $proc->frame_setup($frame_ary);
    $proc->{settings}{highlight} = 0;
    $cmd->run([$NAME]);
    print '-' x 20, "\n";
    $cmd->run([$NAME]);
    print '-' x 20, "\n";
    $cmd->run(["{$NAME}>", __FILE__, __LINE__]);
    print '-' x 20, "\n";
    $cmd->run(["{$NAME}>", __FILE__, 1]);
}

1;
