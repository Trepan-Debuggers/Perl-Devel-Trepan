# -*- coding: utf-8 -*-
# Copyright (C) 2011, 2012 Rocky Bernstein <rocky@cpan.org>

package Devel::Trepan::Client;
use strict;
use rlib;

# require_relative 'default'                # default debugger settings

use Devel::Trepan::Interface::ComCodes;
use Devel::Trepan::Interface::Client;
use Devel::Trepan::Interface::Script;
use English qw( -no_match_vars );

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

sub run_command($$$$)
{
    my ($self, $intf, $current_command) = @_;
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

sub start_client($)
{
    my $options = shift;
    printf "Client option given\n";
    my $client = Devel::Trepan::Client->new(
        {client      => 1,
         cmdfiles    => [],
         initial_dir => $options->{chdir},
         nx          => 1,
         host        => $options->{host},
         port        => $options->{port}}
    );
    my $intf = $client->{intf};
    my ($control_code, $line);
    while (1) {
        eval {
            ($control_code, $line) = $intf->read_remote;
        };
        if ($EVAL_ERROR) {
            $client->msg("Remote debugged process closed connection");
            last;
        }
        # p [control_code, line]
        if (PRINT eq $control_code) {
            $client->msg("$line");
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
                    $command = $client->{user_inputs}[0]->read_command($line);
                };
                # if ($intf->is_input_eof) {
                #       print "user-side EOF. Quitting...\n";
                #       last;
                # }
                if ($EVAL_ERROR) {
                    if (scalar @{$client->{user_inputs}} == 0) {
                        $client->msg("user-side EOF. Quitting...");
                        last;
                    } else {
                        shift @{$client->{user_inputs}};
                        next;
                    }
                };
                $leave_loop = $client->run_command($intf, $command);
                if ($EVAL_ERROR) {
                    $client->msg("Remote debugged process died");
                    last;
                }
            }
        } elsif (QUIT eq $control_code) { 
            last;
        } elsif (RESTART eq $control_code) { 
            $intf->close;
            # Make another connection..
            $client = Devel::Trepan::Client->new(
                {client      => 1,
                 cmdfiles    => [],
                 initial_dir => $options->{chdir},
                 nx          => 1,
                 host        => $options->{host},
                 port        => $options->{port}}
                );
            $intf = $client->{intf};
        } elsif (SERVERERR eq $control_code) {
            $client->errmsg($line);
        } else {
            $client->errmsg("Unknown control code: '$control_code'");
        }
    }
}

unless (caller) {
    Devel::Trepan::Client::start_client({host=>'127.0.0.1', port=>1954});
}

1;
