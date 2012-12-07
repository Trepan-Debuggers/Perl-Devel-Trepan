# -*- coding: utf-8 -*-
# Copyright (C) 2012 Rocky Bernstein <rocky@cpan.org> 

use rlib '../..';

# A debugger Bullwinkle protocol processor. This includes the debugger commands
# and ties together the debugger core and I/O interface.
package Devel::Trepan::BWProcessor;

use English qw( -no_match_vars );
use Exporter;
use warnings; no warnings 'redefine';

use vars qw(@EXPORT @ISA $eval_result);

# Showing eval results can be done using either data dump package.
use if !@ISA, Data::Dumper; 

# Eval does uses its own variables.
# FIXME: have a way to customize Data:Dumper, PerlTidy etc.
$Data::Dumper::Terse = 1; 
require Data::Dumper;

unless (@ISA) {
    require Devel::Trepan::BWProcessor::Load;
    require Devel::Trepan::BrkptMgr;
    eval "require Devel::Trepan::DB::Display";
    require Devel::Trepan::Interface::Bullwinkle;
    require Devel::Trepan::Processor::Virtual;
    require Devel::Trepan::BWProcessor::Default;
    require Devel::Trepan::BWProcessor::Msg;
    # require Devel::Trepan::CmdProcessor::Help;
    # require Devel::Trepan::CmdProcessor::Hook;
    require Devel::Trepan::BWProcessor::Frame;
    require Devel::Trepan::BWProcessor::Location;
    require Devel::Trepan::CmdProcessor::Eval;
    require Devel::Trepan::BWProcessor::Running;
    require Devel::Trepan::CmdProcessor::Validate;
}
use strict;

use Devel::Trepan::Util qw(hash_merge uniq_abbrev parse_eval_sigil);

@ISA = qw(Exporter Devel::Trepan::Processor::Virtual);

sub new($;$$$) {
    my ($class, $interface, $dbgr, $settings) = @_;
    my $intf;
    my $self = 
      Devel::Trepan::Processor::Virtual::new($class, $interface, $settings);
    unless (defined $interface) {
        $interface = Devel::Trepan::Interface::Bullwinkle->new();
    }
    $self->{actions}        = Devel::Trepan::BrkptMgr->new($dbgr);
    $self->{brkpts}         = Devel::Trepan::BrkptMgr->new($dbgr);
    $self->{displays}       = Devel::Trepan::DisplayMgr->new($dbgr);
    $self->{completions}    = [];
    $self->{dbgr}           = $dbgr;
    $self->{event}          = undef;
    $self->{cmd_queue}      = [];
    $self->{DB_running}     = $DB::running;
    $self->{DB_single}      = $DB::single;
    $self->{interface}     = $interface;
    $self->{last_command}   = undef;
    $self->{leave_cmd_loop} = undef;
    $self->{next_level}     = 30000;  # Virtually infinite;
    $self->{settings}       = hash_merge($settings, DEFAULT_SETTINGS());
    $self->{terminated}     = 0;

    # Place to store response to go back to client.
    $self->{response}       = {};

    # Initial watch point expr value used when a new watch point is set.
    # Set in 'watch' command, and reset here after we get the value back.
    $self->{set_wp}         = undef;

    $self->{skip_count}     = 0;
    $self->load_cmds_initialize;
    # $self->running_initialize;
    # $self->hook_initialize;
    # $self->{unconditional_prehooks}->insert_if_new(10, 
    #                                                $self->{trace_hook}[0],
    #                                                $self->{trace_hook}[1]
    #     ) if $self->{settings}{traceprint};

    # $B::Data::Dumper::Deparse = 1;
    bless $self, $class;
    return $self;
}

sub DESTROY($)
{
    my $self = shift;
    # breakpoint_finalize
}

# Check that we meet the criteria that cmd specifies it needs
sub ok_for_running ($$$$) {
    my ($self, $cmd, $current_command) = @_;
    # FIXME: check things like status is running etc.
    return 1;
}

sub valid_cmd_hash($) {
    my ($cmd) = @_;
    'HASH' eq ref($cmd) and $cmd->{cmd_name};
}

# Run one debugger command. 1 is returned if we want to quit.
sub process_command_and_quit($) 
{
    my $self = shift;
    my $intf = $self->{interface};

    $self->{response} = {};

    return 1 if !defined $intf || $intf->is_input_eof;
    my @cmd_queue = @{$self->{cmd_queue}};
    my $cmd_hash;
    while (!$intf->is_input_eof) {
        # begin
        if (scalar(@cmd_queue) == 0) {
	    $cmd_hash = $intf->read_command();
	    unless (valid_cmd_hash($cmd_hash)) {
		$self->errmsg("invalid input. Expecting a hash reference with key 'cmd_name'");
		$self->{interface}->msg($self->{response});
		return $self->{response};
	    }
	} else {
	    $cmd_hash = shift @cmd_queue;
	    $self->{cmd_queue} = \@cmd_queue;
	}
        last;
        # rescue IOError, Errno::EPIPE => e
        # }
    }

    eval {
        $self->{response} = $self->run_command($cmd_hash);
    };
    if ($EVAL_ERROR) {
        $self->errmsg("internal error: $EVAL_ERROR")
    }
    $self->{interface}->msg($self->{response});
    return $self->{response}
}

sub skip_if_next($$) 
{
    my ($self, $event) = @_;
    return 0 if ('line' ne $event);
    return 0 if $self->{terminated};
    return 0 if eval { no warnings; $DB::tid ne $self->{last_tid} };
    # print  "+++event $event ", $self->{stack_size}, " ", 
    #        $self->{next_level}, "\n";
    return 1 if $self->{stack_size} > $self->{next_level};
}

# This is the main entry point.
sub process_commands($$$;$)
{
    my ($self, $frame, $event, $arg) = @_;

    if ($event eq 'terminated') {
        $self->{terminated} = 1;
        $self->section("Debugged program terminated.  Use 'q' to quit or 'R' to restart.");
    } elsif (!defined($event)) {
        $event = 'unknown';
    }
    
    my $next_skip = 0;
    if ($event eq 'after_eval' or $event eq 'after_nest') {
        handle_eval_result($self);
        if ($event eq 'after_nest') {
            $self->msg("Leaving nested debug level $DB::level");
            $self->frame_setup();
            $self->print_location($event);
        }
    } else {
        $self->{event} = $event;
        $self->frame_setup();

        if ($event eq 'watch') {
            my $msg = sprintf("Watchpoint %s: %s changed", 
                              $arg->id, $arg->expr);
            $self->section($msg);
            my $old_value = defined($arg->old_value) ? $arg->old_value 
                : 'undef';
            $msg = sprintf("old value\t%s", $old_value);
            $self->msg($msg);
            my $new_value = defined($arg->current_val) ? $arg->current_val
                : 'undef';
            $msg = sprintf("new value\t%s", $new_value);
            $self->msg($msg);
            $arg->old_value($arg->current_val);
        }

        $next_skip = skip_if_next($self, $event);
        unless ($next_skip) { 

            # prehooks include traceprint, list, and event saving.
            # $self->{unconditional_prehooks}->run;

            if (index($self->{event}, 'brkpt') < 0 && !$self->{terminated}) {
                # Not a breakpoint and not terminated.

                if ($event eq 'line') {

                    # We may want to not stop because of "step n"; step different, or 
                    # "next"
                    # use Enbugger; Enbugger->stop if 2 == $self->{next_level};
                    if ($self->is_stepping_skip()) {
                        # || $self->{stack_size} <= $self->{hide_level};
                        $self->{dbgr}->step;
                        return;
                    }
                    # trace print sets stepping even when though otherwise
                    # we may be are continuing, nexting, finishing, or
                    # returning.
                    if ($self->{settings}{traceprint}) {
                        $self->{dbgr}->step;
                        return unless 0 == $self->{skip_count};
                    }
                }
            }
        
            $self->print_location($event) unless $self->{terminated};
                 # || $self->{settings}{traceprint};

            ## $self->{eventbuf}->add_mark if $self->{settings}{tracebuffer};
            
            ## $self->{cmdloop_prehooks}->run;
        }
    }
    unless ($next_skip) {
        $self->{leave_cmd_loop} = 0;
        while (!$self->{leave_cmd_loop}) {
            $self->process_command_and_quit;
        }
    }
    unless ($self->{terminated}) {
        $self->{last_tid} = $DB::tid;
        $DB::single       = $self->{DB_single};
    }
    $DB::running = $self->{DB_running};
}

# run current_command, a hash. 
sub run_command($$) 
{
    my ($self, $current_command) = @_;
    my $cmd_name = $current_command->{cmd_name};
    my @cmd_queue = @{$self->{cmd_queue}};
    my %commands = %{$self->{commands}};

    if ($commands{$cmd_name}) {
	my $cmd = $commands{$cmd_name};
	if ($self->ok_for_running($cmd, $current_command)) {
	    $self->{current_command} = $current_command;
	    $self->{response} = $cmd->run($current_command);
	}
    } else {
	my $msg = sprintf 'Undefined command: "%s"', $cmd_name;
	$self->errmsg($msg);
    }
    return $self->{response}
}

unless (caller) {
    my $proc  = Devel::Trepan::BWProcessor->new;
    print $proc->{class}, "\n";
    print $proc->{interface}, "\n";
    my $response = $proc->run_command({'cmd_name' => 'info_program'});
    $proc->{interface}->msg($response);
    if (@ARGV) {
	while (1) {
	    $proc->process_command_and_quit();
	}
    }
}

1;
