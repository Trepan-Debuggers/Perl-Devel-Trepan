# -*- coding: utf-8 -*-
# Copyright (C) 2014 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';

package Devel::Trepan::CmdProcessor::Command::Info::Packages;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;
use Getopt::Long qw(GetOptionsFromArray);

use strict;
our (@ISA, @SUBCMD_VARS);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

## FIXME: do automatically.
our $CMD = "info packages";

unless (@ISA) {
    eval <<"EOE";
    use constant MAX_ARGS => undef;  # Need at most this many - undef -> unlimited.
EOE
}
@ISA = qw(Devel::Trepan::CmdProcessor::Command::Subcmd);
=pod

=head2 Synopsis:

=cut
our $HELP = <<'HELP';
=pod

B<info packages> [I<options>] [I<match>]

options:

    -e | --exact
    -p | --prefix
    -r | --regexp
    -f | --files
    -s | --subs

The default is C<--prefix>

Give package names and optionally the file(s) that package is in for
packages matching I<match>. Options control how to interpret the the
match pattern.

=head2 Examples:

    info packages Tie::            # match all packages that start with Tie::
                                   # e.g. Tie::ExtraHash and Tie::Hash
    info packages -p Tie::         # same as above
    info packages -r ^Tie::        # same as above
    info packages -s Tie::         # same as above, but list the subs
                                   # of each package along with the package
    info packages -e Tie::Hash     # match exactly Tie::Hash
    info packages -e -f Tie::Hash  # same as above but show the file(s) where
                                   # the package is defined
    info packages -r ::Tie$        # match Tie only at the end,
                                   # e.g. ReadLine::Tie
    info packages                  # List all packages

=head2 See also:

L<C<info functions>|Devel::Trepan::CmdProcessor::Command::Info::Functions>, and
L<C<complete>|Devel::Trepan::CmdProcessor::Command::Complete>.

=cut
HELP

our $SHORT_HELP = 'All function names, or those matching REGEXP';
our $MIN_ABBREV = length('pa');

sub complete($$) {
    my ($self, $prefix) = @_;
    my @pkgs = Devel::Trepan::Complete::complete_packages($prefix);
    my @opts = (qw(-r --regexp -p --prefix -s --subs -f --files),
		@pkgs);
    Devel::Trepan::Complete::complete_token(\@opts, $prefix) ;
}

my $DEFAULT_OPTIONS = {
    exact   => 0,
    prefix  => 0,
    regexp  => 0,
    files   => 0,
    funcs   => 0,
};

sub parse_options($$)
{
    my ($self, $args) = @_;
    my %opts = %$DEFAULT_OPTIONS;
    my $result = &GetOptionsFromArray($args,
          '-e'        => \$opts{exact},
          '--exact'   => \$opts{exact},
          '-r'        => \$opts{regexp},
          '--regexp'  => \$opts{regexp},
          '-f'        => \$opts{files},
          '--files'   => \$opts{files},
          '-p'        => \$opts{prefix},
          '--prefix'  => \$opts{prefix},
          '-s'        => \$opts{subs},
          '--subs'    => \$opts{subs}
        );
    # Option consistency checking
    my $count = $opts{exact} + $opts{regexp} + $opts{prefix};
    if ($count == 0) {
	$opts{prefix} = 1;
    } elsif ($count > 1) {
	if ($opts{regexp}) {
	    $self->{proc}->errmsg("regexp option used with prefix and/or exact; regexp used");
	    $opts{prefix} = $opts{exact} = 0;
	} elsif ($opts{prefix}) {
	    $self->{proc}->errmsg("prefix used with exact; prefix used");
	    $opts{exact} = 0;
	}
    }

    \%opts;

}

# FIXME combine with Command::columnize_commands
use Array::Columnize;
sub columnize_pkgs($$)
{
    my ($proc, $commands) = @_;
    my $width = $proc->{settings}->{maxwidth};
    my $r = Array::Columnize::columnize($commands,
                                       {displaywidth => $width,
                                        colsep => '    ',
                                        ljust => 1,
                                        lineprefix => '  '});
    chomp $r;
    return $r;
}

sub run($$)
{
    my ($self, $args) = @_;
    my @args = @$args;
    my $options = parse_options($self, \@args);
    my $proc = $self->{proc};
    my $match = undef;

    if (@args == 3) {
        $match = $args[2];
    }

    my %pkgs;
    foreach my $function (keys %DB::sub) {
	my @parts = split('::', $function);
	if (scalar @parts > 1) {
	    my $func  = pop(@parts);
	    my $pkg = join('::', @parts);
	    $pkgs{$pkg} ||= [{}, {}];
	    if ($options->{files}) {
		my $file_range = $DB::sub{$function};
		if ($file_range =~ /^(.+):(\d+-\d+)/) {
		    my ($filename, $range) = ($1, $2);
		    my $files = $pkgs{$pkg}->[0];
		    $files->{$filename} = 1;
		    $pkgs{$pkg}->[0] = $files;
		}
	    }
	    if ($options->{subs}) {
		my $funcs = $pkgs{$pkg}->[1];
		$funcs->{$func} = 1;
		$pkgs{$pkg}->[1] = $funcs;
	    }

	}
    }
    my @pkgs = keys %pkgs;
    if ($options->{regexp}) {
	@pkgs = grep /$match/, @pkgs if defined $match;
    } elsif ($options->{prefix}) {
	@pkgs = grep /^$match/, @pkgs if defined $match;
    } else {
	@pkgs = grep /^$match$/, @pkgs if defined $match;
    }
    if (scalar @pkgs) {
	if ($options->{files} || $options->{subs}) {
	    for my $pkg (sort @pkgs) {
		if ($options->{subs}) {
		    my $subs = $pkgs{$pkg}->[1];
		    my @subs = sort keys $subs;
		    $proc->section($pkg);
		    if (scalar @subs) {
			my $msg = columnize_pkgs($proc, \@subs);
			$proc->msg($msg);
		    } else {
			$proc->msg($pkg);
		    }
		}
		if ($options->{files}) {
		    my $filename = $pkgs{$pkg}->[0];
		    my @files = sort keys $filename;
		    if (scalar @files) {
			my $file_str = @files == 1 ? 'file' : 'files';
			my $msg = sprintf("%s is in %s %s", $pkg, $file_str,
					  join(', ', @files));
			$proc->msg($msg);
		    } else {
			$proc->msg($pkg);
		    }
		}
	    }
        } else {
	    @pkgs = sort @pkgs;
	    my $msg = columnize_pkgs($proc, \@pkgs);
	    $proc->msg($msg);
	}
    } else {
	$proc->msg('No matching package');
    }
}

unless (caller) {
    require Devel::Trepan;
    # Demo it.
    # require_relative '../../mock'
    # my($dbgr, $parent_cmd) = MockDebugger::setup('show');
    # $cmd = __PACKAGE__->new(parent_cmd);
    # $cmd->run(@$cmd->prefix);
}

# Suppress a "used-once" warning;
$HELP || scalar @SUBCMD_VARS;
