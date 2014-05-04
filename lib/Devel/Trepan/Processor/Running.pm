# -*- coding: utf-8 -*-
# Copyright (C) 2011-2012, 2014 Rocky Bernstein <rocky@cpan.org>
use strict; use warnings;
use rlib '../../..';

use Devel::Trepan::Position;
package Devel::Trepan::Processor;
use English qw( -no_match_vars );

use constant SINGLE_STEPPING_EVENT =>  1;
use constant NEXT_STEPPING_EVENT   =>  2;
use constant DEEP_RECURSION_EVENT  =>  4;
use constant RETURN_EVENT          => 32;


# attr_accessor :stop_condition  # String or nil. When not nil
#                                # this has to eval non-nil
#                                # in order to stop.
# attr_accessor :stop_events     # Set or nil. If not nil, only
#                                # events in this set will be
#                                # considered for stopping. This is
#                                # like core.step_events (which
#                                # could be used instead), but it is
#                                # a set of event names rather than
#                                # a bitmask and it is intended to
#                                # be more temporarily changed via
#                                # "step>" or "step!" commands.
# attr_accessor :to_method

sub continue($$) {
    my ($self, $args) = @_;
    $self->{skip_count} = -1;
    if ($self->{settings}{traceprint}) {
        $self->step();
        return;
    }
    if (scalar @{$args} != 1) {
        # Form is: "continue"
        # my $(line_number, $condition, $negate) =
        #    $self->breakpoint_position($self->{proc}{cmd_argstr}, 0);
        # return unless iseq && vm_offset;
        # $bp = $self->.breakpoint_offset($condition, $negate, 1);
        #return unless bp;
        $self->{leave_cmd_loop} = $self->{dbgr}->cont($args->[1]);
    } else {
        $self->{leave_cmd_loop} = $self->{dbgr}->cont;
    };
    if ($self->{leave_cmd_loop}) {
        $self->{DB_running} = 1;
        $self->{DB_single} =  0;
    }
}

# sub quit(cmd='quit')
# {
#     @next_level      = 32000; # I'm guessing the stack size can't ever
#                             # reach this
#     @next_thread     = undef;
#     @core.skip_count = -1;    # No more event stepping
#     @leave_cmd_loop  = 1;  # Break out of the processor command loop.
#     @settings[:autoirb] = 0;
#     @cmdloop_prehooks.delete_by_name('autoirb');
#     @commands['quit'].run([cmd]);
# }

sub parse_next_step_suffix($$)
{
    my ($self, $step_cmd) = @_;
    my $opts = {};
    my $sigil = substr($step_cmd, -1);
    if ('-' eq $sigil) {
        $opts->{different_pos} = 0;
    } elsif ('+' eq $sigil) {
        $opts->{different_pos} = 1;
    } elsif ('=' eq $sigil) {
        $opts->{different_pos} = $self->{settings}{different};
        # when ('!') { $opts->{stop_events} = {'raise' => 1} };
        # when ('<') { $opts->{stop_events} = {'return' => 1}; }
        # when ('>') {
        #     if (length($step_cmd) > 1 && substr($step_cmd, -2, 1) eq '<')  {
        #       $opts->{stop_events} = {'return' => 1 };
        #     } else {
        #       $opts->{stop_events} = {'call' => 1; }
        #     }
        # }
    } else {
        $opts->{different_pos} = $self->{settings}{different};
    }
    return $opts;
}

# Does whatever setup needs to be done to set to ignore stepping
# to the finish of the current method.
sub finish($$) {
    my ($self, $level_count) = @_;
    $self->{leave_cmd_loop} = 1;
    $self->{skip_count} = -1;
    $self->{DB_running} = 1;
    $self->{dbgr}->finish($level_count);
}

sub next($$)
{
    my ($self, $opts) = @_;
    $self->{different_pos} = $opts->{different_pos};
    $self->{leave_cmd_loop} = 1;
    # NEXT_STEPPING_EVENT is sometimes broken.
    # $self->{DB_single}  = NEXT_STEPPING_EVENT;
    $self->{next_level} = $self->{stack_size};
    $self->{DB_single}  = SINGLE_STEPPING_EVENT;
    $self->{DB_running} = 1;
}

sub step($$)
{
    my ($self, $opts) = @_;
    $self->{different_pos} = $opts->{different_pos};
    $self->{leave_cmd_loop} = 1;
    $self->{DB_single}  = SINGLE_STEPPING_EVENT;
    $self->{next_level} = 30000; # Virtually infinite
    $self->{DB_running} = 1;
}

sub running_initialize($)
{
    my $self = shift;
    $self->{stop_condition}  = undef;
    $self->{stop_events}     = undef;
    $self->{to_method}       = undef;
    $self->{last_pos}        =
	Devel::Trepan::Position->new(pkg => '',  filename => '',
				     line =>'', event=>'');
}

# Should we not stop here?
# Some reasons for skipping:
# -  step count was given.
# - We want to make sure we stop on a different line
# - We want to stop only when some condition is reached (step until ...).
sub is_stepping_skip($)
{

    my $self = shift;
    if ($self->{skip_count} < 0) {
        return 1;
    } elsif ($self->{skip_count} > 0) {
        $self->{skip_count} --;
        return 1
    }

    if ($self->{settings}{'debugskip'}) {
        $self->msg("diff: $self->{different_pos}, event : $self->{event}");
        $self->msg("skip_count  : $self->{skip_count}");
    }

    my $frame = $self->{frame};

    my $new_pos = Devel::Trepan::Position->new(pkg       => $frame->{pkg},
					       filename  => $frame->{file},
					       line      => $frame->{line},
					       event     => $self->{event});

    my $skip_val = 0;

    # If the last stop was a breakpoint, don't stop again if we are at
    # the same location with a line event.

    my $last_pos = $self->{last_pos};
    # $skip_val ||= ($last_pos->event eq 'brkpt' && $self->{event} eq 'line');

    if ($self->{settings}{'debugskip'}) {
        $self->msg("skip: $skip_val, last: $self->{last_pos}->inspect(), " .
                   "new: $new_pos->inspect()");
    }

    # @last_pos[2] = new_pos[2] if 'nostack' eq $self->{different_pos};

    my $condition_met = 1;
    # if (! $skip_val) {
    #   if (@stop_condition) {
    #       puts 'stop_cond' if @settings[:'debugskip'];
    #       debug_eval_no_errmsg(@stop_condition);
    # } elsif (@to_method) {
    #   puts "method #{@frame.method} #{@to_method}" if
    #       $self->{setting}{'debugskip'};
    #   @frame.method == @to_method;
    # } else {
    #   puts 'uncond' if $self->{settings}{'debugskip'};
    #   1;
    # };

    # $self->msg("condition_met: #{condition_met}, last: $self->{last_pos}, " .
    #      "new: $new_pos->inspect(), different #{@different_pos.inspect}") if
    #          $self->{settings}{'debugskip'};

    $skip_val = (($last_pos && $last_pos->eq($new_pos) && !!$self->{different_pos})
                 || !$condition_met);

    $self->{last_pos} = $new_pos;

    unless ($skip_val) {
        # Set up the default values for the next time we consider
        # skipping.
        $self->{different_pos} = $self->{settings}{different};
    }

    return $skip_val;
}

sub restart_args($$) {
    my $self = shift;
    my @flags = ();
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

    ( $EXECUTABLE_NAME, @flags, '-d:Trepan', $DB::ini_dollar0,
      @{$self->{dbgr}{exec_strs}},
      @DB::ini_ARGV );
}

1;
