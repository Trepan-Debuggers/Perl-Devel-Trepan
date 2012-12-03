# Copyright (C) 2012 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';

use rlib '../../../..';

package Devel::Trepan::BWProcessor::Command::Status;
use if !@ISA, Devel::Trepan::BWProcessor::Command ;

use strict;

use vars qw(@ISA); @ISA = @CMD_ISA; 
use vars @CMD_VARS;  # Value inherited from parent

# This method runs the command
sub run($$)
{
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    {
	'name' => 'status',
	'response' => {
	    "status" => "ready",
	}
    }
}

unless (caller) {
    my $cmd = __PACKAGE__->new();
    my $value = $cmd->run({});
    require Data::Dumper;
    print Data::Dumper::Dumper($value), "\n";
}

1;
