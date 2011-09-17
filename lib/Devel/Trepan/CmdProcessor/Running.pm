# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org> 
use strict; use warnings;
use feature 'switch';
use lib '../../..';

package Devel::Trepan::CmdProcessor;
use English;

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

# # Does whatever needs to be done to set to continue program
# # execution.
# # FIXME: turn line_number into a condition.
# sub continue {
#     @next_level      = 32000; # I'm guessing the stack size can't ever
# 			      # reach this
#     @next_thread     = undef;
#     @core.step_count = -1;    # No more event stepping
#     @leave_cmd_loop  = 1;  # Break out of the processor command loop.
# }

# # Does whatever setup needs to be done to set to ignore stepping
# # to the finish of the current method.
# sub finish(level_count=0, opts={}) {
#     step(0, opts);
#     @next_level        = @frame.stack_size - level_count;
#     @next_thread       = Thread.current;
#     @stop_events       = Set.new(%w(return leave yield));
    
#     # Try high-speed (run-time-assisted) method
#     @frame.trace_off   = 1;  # No more tracing in this frame
#     @frame.return_stop = 1;  # don't need to 
# }

# # Does whatever needs to be done to set to do "step over" or ignore
# # stepping into methods called from this stack but step into any in 
# # the same level. We do this by keeping track of the number of
# # stack frames and the current thread. Elsewhere in "skipping_step?"
# # we do the checking.
# sub next(step_count=1, opts={}) 
# {
#     step(step_count, opts);
#     @next_level      = @top_frame.stack_size;
#     @next_thread     = Thread.current;
# }

# # Does whatever needs to be done to set to step program
# # execution.
# sub step(step_count=1, opts={}, condition=undef) 
# {
#     $self->continue();
#     @core.step_count = step_count;
#     @different_pos   = opts[:different_pos] if 
#         opts.keys.member?(:different_pos);
#     @stop_condition  = condition;
#     @stop_events     = opts[:stop_events]   if 
#         opts.keys.member?(:stop_events);
#     @to_method       = opts[:to_method];
# }

# sub quit(cmd='quit')
# {
#     @next_level      = 32000; # I'm guessing the stack size can't ever
# 			      # reach this
#     @next_thread     = undef;
#     @core.step_count = -1;    # No more event stepping
#     @leave_cmd_loop  = 1;  # Break out of the processor command loop.
#     @settings[:autoirb] = 0;
#     @cmdloop_prehooks.delete_by_name('autoirb');
#     @commands['quit'].run([cmd]);
# }

sub parse_next_step_suffix($$)
{
    my ($self, $step_cmd) = @_;
    my $opts = {};
    given (substr($step_cmd, -1)) {
	when ('-') { $opts->{different_pos} = 0; }
	when ('+') { $opts->{different_pos} = 'nostack'; }
	when ('=') { $opts->{different_pos} = 1; }
	# when ('!') { $opts->{stop_events} = {'raise' => 1} };
	# when ('<') { $opts->{stop_events} = {'return' => 1}; }
	# when ('>') { 
	#     if (length($step_cmd) > 1 && substr($step_cmd, -2, 1) eq '<')  {
	#     	$opts->{stop_events} = {'return' => 1 };
	#     } else {
	# 	$opts->{stop_events} = {'call' => 1; }
	#     }
	# }
    }
    return $opts;
}

sub running_initialize($)
{
    my $self = shift;
    $self->{stop_condition}  = undef;
    $self->{stop_events}     = undef;
    $self->{to_method}       = undef;
    # FIXME: Use a struct;
    $self->{last_pos}        = [undef, undef, undef, undef];
}

sub is_stepping_skip()
{

    my $self = shift;
    return 1 if $self->{step_count} < 0;

    if ($self->{settings}{'debugskip'}) {
        $self->msg("diff: $self->{different_pos}, event : $self->{event}");
	$self->msg("step_count  : $self->{step_count}");
    }

    my $frame = $self->{frame};
    # FIXME: use a struct;
    my $new_pos = [$frame->{pkg}, $frame->{file}, $frame->{line}];

    my $skip_val = 0;

    # # If the last stop was a breakpoint, don't stop again if we are at
    # # the same location with a line event.

    # $skip_val ||= ($self->{last_pos}->[4] eq 'brkpt' && 
    # 		   $self->{event} eq 'line');
    
    if ($self->{settings}{'debugskip'}) {
        $self->msg("skip: $skip_val, last: $self->{last_pos}, new: $self->{new_pos}"); 
    }

    # @last_pos[2] = new_pos[2] if 'nostack' eq @different_pos;

    my $condition_met;
    # if (! $skip_val) {
    # 	if (@stop_condition) {
    # 	    puts 'stop_cond' if @settings[:'debugskip'];
    # 	    debug_eval_no_errmsg(@stop_condition);
    # } elsif (@to_method) {
    # 	puts "method #{@frame.method} #{@to_method}" if 
    # 	    @setting->{'debugskip'};
    # 	@frame.method == @to_method;
    # } else {
    # 	puts 'uncond' if @settings[:'debugskip'];
    # 	1;
    # };
          
    # $self->msg("condition_met: #{condition_met}, last: #{@last_pos}, " .
    # 	       "new: #{new_pos}, different #{@different_pos.inspect}") if 
    # 	       $self->{settings}{'debugskip'};

    # $skip_val = (($last_pos->[0] eq $new_pos->[0] 
    # 		  && $settings->{different_pos}) ||
    # 		!$condition_met);

    # @last_pos = new_pos if !@stop_events || @stop_events.member?(@event);

    unless ($skip_val) {
        # Set up the default values for the
        # next time we consider skipping.
        $self->{settings}{different_pos} = $self->{settings}{different};
    }

    return $skip_val;
}

1;

