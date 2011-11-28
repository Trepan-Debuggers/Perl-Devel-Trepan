# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>

use strict;
use rlib '../..';
use feature 'switch';

# require_relative 'default'                # default debugger settings

package Devel::Trepan::Client;
use Devel::Trepan::Interface::ComCodes;
use Devel::Trepan::Interface::Client;

sub new
{
    my ($class, $settings) = @_;
    my $self = {
	intf => Devel::Trepan::Interface::Client->new( 
	    undef, undef, undef, undef, 
	    {host => $settings->{host},
	     port => $settings->{port}}
	)
    };
    bless $self, $class;
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
      # begin
        ($control_code, $line) = $intf->read_remote;
      # rescue EOFError, Errno::EPIPE
      #  puts "Remote debugged process closed connection"
      #  last
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
		# require 'trepanning'
		# debugger
		# begin
		my $command = $intf->read_command($line);
		# rescue EOFError
		# puts "user-side EOF. Quitting..."
		# last
		# }
		# begin 
		$intf->write_remote(COMMAND, $command);
		# rescue Errno::EPIPE
		# print "Remote debugged process died\n";
		# last
	    }
	    when (QUIT) { last }
	    when (RESTART) { last }
	    default {
		print STDERR "** Unknown control code: '$control_code'\n";
	    }
	}
    }
}

unless (caller) {
    Devel::Trepan::Client::start_client({host=>'127.0.0.1', port=>1954});
}

1;
