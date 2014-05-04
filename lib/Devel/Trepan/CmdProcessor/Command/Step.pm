# -*- coding: utf-8 -*-
# Copyright (C) 2011-2012, 2014 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';

use rlib '../../../..';

# require_relative '../../app/condition'

package Devel::Trepan::CmdProcessor::Command::Step;

use if !@ISA, Devel::Trepan::CmdProcessor::Command ;

unless (@ISA) {
    eval <<'EOE';
use constant ALIASES  => qw(s step+ step- s+ s-);
use constant CATEGORY => 'running';
use constant SHORT_HELP => 'Step program (possibly entering called functions)';
use constant MIN_ARGS   => 0;     # Need at least this many
use constant MAX_ARGS   => undef; # Need at most this many - undef -> unlimited.
use constant NEED_STACK => 1;
EOE
}

use strict;
use vars qw(@ISA); @ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

$NAME = set_name();
$HELP = <<'HELP';
=pod

B<step>[B<+>|B<->] [B<into>] [I<count>]

B<step over>

B<step out>

Execute the current line, stopping at the next event.  Sometimes this
is called "step into".

With an integer argument, step that many times.  With an 'until'
expression that expression is evaluated and we stop the first time it
is true.

A suffix of C<+> in a command or an alias forces a move to another
position, while a suffix of C<-> disables this requirement.  A suffix
of C<E<gt>> will continue until the next call. (C<finish> will run run until
the return for that call.)

If no suffix is given, the debugger setting C<different> determines
this behavior.

=head2 Examples:

 step        # step 1 event, any event obeying 'set different' setting
 step 1      # same as above
 step+       # same but force stopping on a new line
 step-       # same but force stopping on a new line a new frame added
 step over   # same as 'next'
 step out    # same as 'finish'

=head2 See also:

L<C<next> (step over)|Devel::Trepan::CmdProcessor::Command::Step>,
L<C<finish> (step out)|Devel::Trepan::CmdProcessor::Command::Finish>,
L<C<continue>|Devel::Trepan::CmdProcessor::Command::Continue>, and
L<C<set different>|Devel::Trepan::CmdProcessor::Command::Set::Different>.

=cut
HELP

my $Keyword_to_related_cmd = {
    'out'  => 'finish',
    'over' => 'next',
    'into' => 'step',
};

#  include Trepan::Condition

# This method runs the command
sub run($$) {
    my ($self, $args) = @_;

    my $proc = $self->{proc};
    my $opts = $proc->parse_next_step_suffix($args->[0]);
    # condition = nil
    if (0 == $#$args) {
        # Form is: "step" which means "step 1"
        $proc->{skip_count} = 0;
    } else {
        my $replace_cmd = $Keyword_to_related_cmd->{$args->[1]};
        if (defined($replace_cmd)) {
            my $cmd = $proc->{commands}{$replace_cmd};
            return $cmd->run( [$replace_cmd, splice(@$args, 2)] );
    #   } elsif ('until' eq $args->[1]) {
    #     my $try_condition = join(@$args[2..-1], ' ');
    #     if (valid_condition?(try_condition)) {
    #       $condition = $try_condition;
    #       $opts-{different_pos} = 0;
    #       $proc->{skip_count} = 0;
    #     }
    #   elsif('to' eq $args[1]) {
    #     if args.size != 3;
    #       $self->errmsg('Expecting a method name after "to"');
    #       return;
    #     elsif (!@proc.method?(args[2])) {
    #       $self->errmsg("${args[2]} doesn't seem to be a method name");
    #       return;
    #     } else {
    #       $opts->{to_method{ = $args->[2];
    #       $opts->{different_pos} = 0;
    #       skip_count = 0
    #     }
    #   } elsif ('thread' eq $args->[1]) {
    #     $condition = "Thread.current.object_id == ${Thread.current.object_id}"
    #     $opts[:different_pos] = 0;
    #     $proc->{skip_count] = 0;
        } else {
            my $count_str = $args->[1];
            my $int_opts = {
                msg_on_error =>
                    "The 'step' command argument must eval to an integer. Got: ${count_str}",
                    min_value => 1
            };
            #     }.merge(opts)
            my $count = $proc->get_an_int($count_str, $int_opts);
            return unless defined($count);
            # step 1 is $proc->{skip_count} = 0 or "stop next event"
            $proc->{skip_count} = $count - 1  ;
        }
    }
    $proc->step($opts)
}

unless (caller) {
  # require_relative '../mock'
  # dbgr, cmd = MockDebugger::setup
  # p cmd.run([cmd.name])
}

1;
