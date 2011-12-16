# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>

use strict;
eval "use rlib '../..'";
use feature 'switch';

# require_relative 'default'                # default debugger settings

package Devel::Trepan::Client;
use Devel::Trepan::Interface::ComCodes;
use Devel::Trepan::Interface::Client;
use Devel::Trepan::Interface::Script;
use English;

sub new
{
    my ($class, $settings) = @_;
    my  $intf = Devel::Trepan::Interface::Client->new( 
	undef, undef, undef, undef, 
	{host => $settings->{host},
	 port => $settings->{port}}
	);
    my $self = {
	intf => $intf,
	user_inputs => [$intf->{user}]
    };
    bless $self, $class;
}

# FIXME: use routine from a User interface. Also use msg() later on.
sub errmsg($$)
{
    my ($self, $msg) = @_;
    print STDERR "** $msg\n";
}

sub run_command($$$$)
{
    my ($self, $intf, $current_command) = @_;
    if (substr($current_command, 0, 1) eq '.') {
	$current_command = substr($current_command, 1);
        my @args = split(' ', $current_command);
	my $cmd_name = shift @args;
	my $script_file = shift @args;
	given($cmd_name) {
	    when ("source") { 
		# FIXME expand ~ and pats and verify file name.
		my $script_intf = 
		    Devel::Trepan::Interface::Script->new($script_file);
		unshift @{$self->{user_inputs}}, $script_intf->{input};
		$current_command = $script_intf->read_command;
	    };
	    default {
		$self->errmsg(sprintf "Unknown command: '%s'", $cmd_name);
		return 0;
	    }
	};
    } eval {
	$intf->write_remote(COMMAND, $current_command);
    };
    return 1;
}

sub start_client($)
{
    my $options = shift;
    printf "Client option given\n";
    my $dbgr = Devel::Trepan::Client->new(
	{client      => 1,
	 cmdfiles    => [],
	 initial_dir => $options->{chdir},
	 nx          => 1,
	 host        => $options->{host},
	 port        => $options->{port}}
    );
    my $intf = $dbgr->{intf};
    my ($control_code, $line);
    while (1) {
	eval {
	    ($control_code, $line) = $intf->read_remote;
	};
	if ($EVAL_ERROR) {
	    print "Remote debugged process closed connection\n";
	    last;
	}
	# p [control_code, line]
	given ($control_code) {
	    when (PRINT) { print "$line"; }
	    when (CONFIRM_TRUE) {
		my $response = $intf->confirm($line, 1);
		$intf->write_remote(CONFIRM_REPLY, $response ? 'Y' : 'N');
	    }
	    when (CONFIRM_FALSE) {
		my $response = $intf->confirm($line, 1);
		$intf->write_remote(CONFIRM_REPLY, $response ? 'Y' : 'N');
	    }
	    when (PROMPT) {
		my $command;
		my $leave_loop = 0;
		until ($leave_loop) {
		    eval {
			$command = $dbgr->{user_inputs}[0]->read_command($line);
		    };
		    # if ($intf->is_input_eof) {
		    # 	print "user-side EOF. Quitting...\n";
		    # 	last;
		    # }
		    if ($EVAL_ERROR) {
			if (scalar @{$dbgr->{user_inputs}} == 0) {
			    print "user-side EOF. Quitting...\n";
			    last;
			} else {
			    shift @{$dbgr->{user_inputs}};
			    next;
			}
		    };
		    $leave_loop = $dbgr->run_command($intf, $command);
		    if ($EVAL_ERROR) {
			print "Remote debugged process died\n";
			last;
		    }
		}
	    }
	    when (QUIT) { 
		last 
	    }
	    when (RESTART) { 
		$intf->close;
		# Make another connection..
		$dbgr = Devel::Trepan::Client->new(
		    {client      => 1,
		     cmdfiles    => [],
		     initial_dir => $options->{chdir},
		     nx          => 1,
		     host        => $options->{host},
		     port        => $options->{port}}
		    );
		$intf = $dbgr->{intf};
	    }
	    when (SERVERERR) {
		$dbgr->errmsg($line);
	    }
	    default {
		$dbgr->errmsg("Unknown control code: '$control_code'");
	    }
	}
    }
}

unless (caller) {
    Devel::Trepan::Client::start_client({host=>'127.0.0.1', port=>1954});
}

1;
