# -*- coding: utf-8 -*-
# Copyright (C) 2011-2012 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';

use rlib '../../../..';

# Our local modules
## use Devel::Trepan::Options; or is it default
use Devel::Trepan::Interface::Server;

package Devel::Trepan::CmdProcessor::Command::Server;
use Cwd 'abs_path';
use Getopt::Long qw(GetOptionsFromArray);
use if !@ISA, Devel::Trepan::CmdProcessor::Command ;

unless (@ISA) {
    eval <<'EOE';
use constant CATEGORY   => 'support';
use constant SHORT_HELP => 'Allow remote connections';
use constant MIN_ARGS   => 0;     # Need at least this many
use constant MAX_ARGS   => undef; # Need at most this many - undef -> unlimited.
EOE
}

use strict;

use vars qw(@ISA); @ISA = qw(Devel::Trepan::CmdProcessor::Command);
use vars @CMD_VARS;  # Value inherited from parent

$NAME = set_name();
$HELP = <<"HELP";
=pod

server [I<options>]

options: 

    -p | --port NUMBER
    -a | --address

Put debugger in server mode which opens a socket for debugger connections
=cut
HELP

# FIXME: put back in help.
# Note that the command startup file ${Devel::Trepan::CMD_INITFILE_BASE} is read automatically
# via a ${NAME} command the debugger is started.

my $DEFAULT_OPTIONS = {
    port => 1954,
    host => '127.0.0.1',
};

# sub complete($$) {
#     my ($self, $prefix) = @_;
#     my $files = Readline::FILENAME_COMPLETION_PROC.call(prefix) || []
#     my $opts = (qw(-c --continue --no-continue -N --no -y --yes
#               --verbose --no-verbose), $files);
#     Devel::Trepan::Complete::complete_token($opts, $prefix) ;
# }
    
sub parse_options($$)
{
    my ($self, $args) = @_;
    my $seen_yes_no = 0;
    my %opts = %{$DEFAULT_OPTIONS};
    my $result = &GetOptionsFromArray($args,
          'port:n' => \$opts{port},
          'host:s' => \$opts{host},
        );
    \%opts;
}

sub run($$)
{
    my ($self, $args)  = @_;
    my @args           = @$args;
    my $proc           = $self->{proc};
    my $options        = parse_options($self, \@args);
    my $intf           = $proc->{interfaces};
    $options->{logger} = $intf->[-1]{output}{output};
    # Push a new server interface.
    my $script_intf = Devel::Trepan::Interface::Server->new(undef, undef,
                                                            $options);
    push @{$intf}, $script_intf;
}

  
# Demo it
unless (caller) {
  # require_relative '../mock'
  # dbgr, cmd = MockDebugger::setup
  # %w(--quiet -q --no-quiet --continue --no-continue -c -v --verbose 
  #    --no-verbose).each do |opt|
  #   puts "parsing ${opt}"
  #   options = 
  #     cmd.parse_options(Trepan::Command::SourceCommand::DEFAULT_OPTIONS.dup,
  #                       opt)
  #   p options
  # }

  # if ARGV.size >= 1 
  #   puts "running... ${cmd.name} ${ARGV}"
  #   cmd.run([cmd.name, *ARGV])
  # }
}

1;
