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
    -v | --verbose | --no-verbose

The default is C<--prefix>

Give package names and optionally the file(s) that package is in for
packages matching I<match>. Options control how to interpret the the
match pattern.

=head2 Examples

    info packages Tie::            # match all packages that start with Tie::
                                   # e.g. Tie::ExtraHash and Tie::Hash
    info packages -p Tie::         # same as above
    info packages -r ^Tie::        # same as above
    info packages -e Tie::Hash     # match exactly Tie::Hash
    info packages -e -v Tie::Hash  # same as above but show the file(s) where
                                   # the package is defined
    info packages -r ::Tie$        # match Tie only at the end,
                                   # e.g. ReadLine::Tie
    info packages                  # List all packages
=cut
HELP

our $SHORT_HELP = 'All function names, or those matching REGEXP';
our $MIN_ABBREV = length('pa');

sub complete($$) {
    my ($self, $prefix) = @_;
    my @files = (); # Devel::Trepan::Complete::package_list($prefix);
    my @opts = (qw(-r --regexp -p --prefix -v --verbose), @files);
    Devel::Trepan::Complete::complete_token(\@opts, $prefix) ;
}

my $DEFAULT_OPTIONS = {
    exact   => 0,
    prefix  => 1,
    regexp  => 0,
    verbose => 0
};

sub parse_options($$)
{
    my ($self, $args) = @_;
    my %opts = %$DEFAULT_OPTIONS;
    my $result = &GetOptionsFromArray($args,
          '-r'        => \$opts{regexp},
          '--regexp'  => \$opts{regexp},
          '-v'        => \$opts{verbose},
          '-verbose'  => \$opts{verbose},
          '-p'        => \$opts{prefix},
          '--prefix'  => \$opts{prefix},
          '-e'        => \$opts{exact},
          '--exact'   => \$opts{exact}
        );
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
	    pop(@parts);
	    my $pkg = join('::', @parts);
            my $file_range = $DB::sub{$function};
            if ($file_range =~ /^(.+):(\d+-\d+)/) {
                my ($filename, $range) = ($1, $2);
		my $files = $pkgs{$pkg} ||= {};
		$files->{$filename} = 1;
		$pkgs{$pkg} = $files;
            } else {
		$pkgs{$pkg} = {};
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
	if ($options->{verbose}) {
	    for my $pkg (sort @pkgs) {
		my $filename = $pkgs{$pkg};
		my @files = sort keys $filename;
		if (scalar @files && $options->{verbose}) {
		    my $file_str = @files == 1 ? 'file' : 'files';
		    my $msg = sprintf("%s is in %s %s", $pkg, $file_str,
				      join(', ', @files));
		    $proc->msg($msg);
		} else {
		    $proc->msg($pkg);
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
