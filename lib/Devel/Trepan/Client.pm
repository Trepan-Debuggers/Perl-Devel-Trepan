# -*- coding: utf-8 -*-
# Copyright (C) 2011-2014 Rocky Bernstein <rocky@cpan.org>

package Devel::Trepan::Client;
use strict;
use English qw( -no_match_vars );

BEGIN {
    my @OLD_INC = @INC;
    use rlib '../..';
    use Devel::Trepan::Interface::ComCodes;
    use Devel::Trepan::Interface::Client;
    use Devel::Trepan::Interface::Script;
    @INC = @OLD_INC;
}

sub new
{
    my ($class, $settings) = @_;
    my $opts = $settings;
    my  $intf = Devel::Trepan::Interface::Client->new(
        undef, undef, undef, $settings );
    my $self = {
	leave_loop    => 0,
	options       => $settings,
        intf          => $intf,
        user_inputs   => [$intf->{user}],
    };
    bless $self, $class;
}

sub handle_server_reponse($$$);

sub errmsg($$)
{
    my ($self, $msg) = @_;
    $self->{intf}{user}->errmsg($msg);
}

sub msg($$)
{
    my ($self, $msg) = @_;
    chomp $msg;
    $self->{intf}{user}->msg($msg);
}

sub list_complete {
    print "List complete called\n", join(", ", @_), "\n";
}

sub complete($$$$$) {
    my ($self, $text, $line, $start, $end) = @_;
    my $intf = $self->{intf};
    # print "complete called: text: $text, line: " .
    #       $line, start: $start, end: $end\n");
    eval {
        $intf->write_remote(COMMAND, "complete " . $line);
    };
    my ($control_code, $line);
    my @complete;
    eval {
	($control_code, $line) = $intf->read_remote;
	while (PROMPT ne $control_code) {
	    if (PRINT eq $control_code) {
		chomp $line;
		push @complete, $line;
		($control_code, $line) = $intf->read_remote;
	    } else {
		$self->errmsg("Was expecting a print response, got $control_code\n+++ $line");
		return $line;
	    }
	}
    };
    chomp $line;
    return @complete;
}

sub run_command($$$$)
{
    my ($self, $current_command) = @_;
    my $intf = $self->{intf};
    if (substr($current_command, 0, 1) eq '.') {
        $current_command = substr($current_command, 1);
        my @args = split(' ', $current_command);
        my $cmd_name = shift @args;
        my $script_file = shift @args;
        if ('source' eq $cmd_name) {
            my $result =
                Devel::Trepan::Util::invalid_filename($script_file);
            unless (defined $result) {
                $self->errmsg($result);
                return 0;
            }
            my $script_intf =
                Devel::Trepan::Interface::Script->new($script_file);
            unshift @{$self->{user_inputs}}, $script_intf->{input};
            $current_command = $script_intf->read_command;
        } else {
            $self->errmsg(sprintf "Unknown command: '%s'", $cmd_name);
            return 0;
        };
    } eval {
        $intf->write_remote(COMMAND, $current_command);
    };
    return 1;
}

sub handle_server_reponse($$$) {
    my ($self, $control_code, $line) = @_;
    my $intf = $self->{intf};
    my $options = $self->{options};

    # p [control_code, line]
    if (PRINT eq $control_code) {
	$self->msg($line);
    } elsif (CONFIRM_TRUE eq $control_code) {
	my $response = $intf->confirm($line, 1);
	$intf->write_remote(CONFIRM_REPLY, $response ? 'Y' : 'N');
    } elsif (CONFIRM_FALSE eq $control_code) {
	my $response = $intf->confirm($line, 1);
	$intf->write_remote(CONFIRM_REPLY, $response ? 'Y' : 'N');
    } elsif (PROMPT eq $control_code) {
	my $command;
	my $leave_loop = 0;
	until ($leave_loop) {
	    eval {
		$command = $self->{user_inputs}[0]->read_command($line);
	    };
	    # if ($intf->is_input_eof) {
	    #       print "user-side EOF. Quitting...\n";
	    #       last;
	    # }
	    if ($EVAL_ERROR) {
		if (scalar @{$self->{user_inputs}} == 0) {
		    $self->msg("user-side EOF. Quitting...");
		    $self->{leave_loop} = 1;
		    return;
		} else {
		    shift @{$self->{user_inputs}};
		    next;
		}
	    };
	    $leave_loop = $self->run_command($command);
	    if ($EVAL_ERROR) {
		$self->msg("Remote debugged process died");
		$self->{leave_loop} = 1;
		return;
	    }
	}
    } elsif (QUIT eq $control_code) {
	$self->{leave_loop} = 1;
	return;
    } elsif (RESTART eq $control_code) {
	$intf->close;
	# Make another connection..
	$self = Devel::Trepan::Client->new(
	    {client      => 1,
	     cmdfiles    => [],
	     initial_dir => $options->{chdir},
	     nx          => 1,
	     host        => $options->{host},
	     port        => $options->{port}}
	    );
	$intf = $self->{intf};
    } elsif (SERVERERR eq $control_code) {
	$self->errmsg($line);
    } else {
	$self->errmsg("Unknown control code: '$control_code'");
    }
}

sub start_client($)
{
    my $options = shift;
    printf "Client option given\n";
    my $client = Devel::Trepan::Client->new($options);

    my $intf = $client->{intf};
    if ($intf->has_completion) {
        my $list_completion = sub {
            my($text, $state) = @_;
            list_complete($text, $state);
        };
        my $completion = sub {
            my ($text, $line, $start, $end) = @_;
            $client->complete($text, $line, $start, $end);
        };
        $intf->set_completion($completion, $list_completion);
    }

    my ($control_code, $line);
    until ($client->{leave_loop}) {
	eval {
	    ($control_code, $line) = $intf->read_remote;
	};
	if ($EVAL_ERROR) {
	    $client->msg("$EVAL_ERROR");
	    $client->msg("Remote debugged process may have closed connection");
	    last;
	}
	$client->handle_server_reponse($control_code, $line);
    }
}

unless (caller) {
    # Devel::Trepan::Client::start_client(
    # {client =>['tcp', '127.0.0.1', port=>1954]});
    # Devel::Trepan::Client::start_client(
    # {client =>['tty'], logger => \*STDOUT});
    Devel::Trepan::Client::start_client(
	{client=>['tty', '/dev/pts/4', '/dev/pts/2'],
	 logger => \*STDOUT});
}
1;
