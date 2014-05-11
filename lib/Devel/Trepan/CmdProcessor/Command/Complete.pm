# -*- coding: utf-8 -*-
# Copyright (C) 2011-2014 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; use utf8;

use rlib '../../../..';

package Devel::Trepan::CmdProcessor::Command::Complete;

use Getopt::Long qw(GetOptionsFromArray);
use Devel::Trepan::Complete
    qw(complete_packages complete_subs complete_builtins);

use if !@ISA, Devel::Trepan::CmdProcessor::Command ;

unless (@ISA) {
    eval <<'EOE';
    use constant CATEGORY   => 'support';
    use constant SHORT_HELP => 'List the completions for the rest of the line as a command';
    use constant MAX_ARGS   => undef;  # Need at most this many -
                                       # undef -> unlimited
    use constant NEED_STACK => 0;
EOE
}

use strict;
use vars qw(@ISA);
@ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
our $HELP = <<"HELP";
=pod

B<complete> [I<options>] I<prefix>

options:

    -b | --builtins
    -f | --files
    -p | --packages
    -s | --subs


List the command completions of I<prefix>.

=head2 Examples:

    complete se        # => set server
    complete -p Tie::H # => Tie::Hash (probably)
    complete -s Tie::Hash::n
                       # => Tie::Hash::new

=cut
HELP

my $DEFAULT_OPTIONS = {
    lexicals   => 0,
    files      => 0,
    'my'       => 0,
    'our'      => 0,
    packages   => 0,
    subs       => 0,
};

sub parse_options($$)
{
    my ($self, $args) = @_;
    my %opts = %$DEFAULT_OPTIONS;
    my $result = &GetOptionsFromArray
	($args,
	 '-b'         => \$opts{builtins},
	 '--builtins' => \$opts{builtins},
	 '-f'         => \$opts{files},
	 '--files'    => \$opts{files},
	 '-p'         => \$opts{packages},
	 '--packages' => \$opts{packages},
	 '-s'         => \$opts{subs},
	 '--subs'     => \$opts{subs}
        );

    \%opts;

}

# This method runs the command
sub run($$) {
    my ($self, $args) = @_;
    my @args = @{$args}; shift @args; # remove "complete".
    my $opts = parse_options($self, \@args);

    my $proc = $self->{proc};

    if ($opts->{files}) {
	if (scalar @args != 1) {
	    $proc->errmsg('Expecting only a single argument after options');
	    return;
	}
	foreach my $file ($proc->filename_complete($args[0])) {
	    $proc->msg($file);
	}
    } elsif ($opts->{builtins}||$opts->{packages}||$opts->{subs}) {
	if (scalar @args != 1) {
	    $proc->errmsg('Expecting only a single argument after options');
	    return;
	}
	my $prefix = $args[0];
	my @matches = ();
	push @matches, complete_builtins($prefix) if ($opts->{builtins});
	push @matches, complete_packages($prefix) if ($opts->{packages});
	push @matches, complete_subs($prefix)     if ($opts->{subs});
	for my $match (@matches) {
	    $proc->msg($match);
	}
    } else {
	my $cmd_argstr = $proc->{cmd_argstr};
	my $last_arg = (' ' eq substr($cmd_argstr, -1)) ? '' : $args[-1];
	$last_arg = '' unless defined $last_arg;
	for my $match ($proc->complete($cmd_argstr, $cmd_argstr,
				       0, length($cmd_argstr))) {
	    $proc->msg($match);
	}
    }
}

unless (caller) {
    require Devel::Trepan::CmdProcessor;
    my $proc = Devel::Trepan::CmdProcessor->new;
    my $cmd = __PACKAGE__->new($proc);
    for my $prefix (qw(d b bt)) {
        $cmd->{proc}{cmd_argstr} = $prefix;
        $cmd->run([$cmd->name, $prefix]);
        print '=' x 40, "\n";
    }
    for my $prefix ('set a') {
        $cmd->{proc}{cmd_argstr} = $prefix;
        $cmd->run([$cmd->name, $prefix]);
        print '=' x 40, "\n";
    }
    for my $prefix ('help syntax c') {
        $cmd->{proc}{cmd_argstr} = $prefix;
        $cmd->run([$cmd->name, $prefix]);
        print '=' x 40, "\n";
    }

    %DB::sub = (__PACKAGE__ . '::run', 1);
    for my $tuple (['-b', 'call'], ['-p', __PACKAGE__],
		   ['-s', __PACKAGE__ . '::r']) {
	my ($opt, $prefix) = @$tuple;
        $cmd->{proc}{cmd_argstr} = $prefix;
        $cmd->run([$cmd->name, $opt, $prefix]);
        print '=' x 40, "\n";
    }
    # $cmd->run([$cmd->name, 'fdafsasfda']);
}

1;
