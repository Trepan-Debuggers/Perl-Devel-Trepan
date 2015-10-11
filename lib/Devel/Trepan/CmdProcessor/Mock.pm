# -*- coding: utf-8 -*-
use strict; use warnings;
use Exporter;

use vars qw(@EXPORT @ISA); @ISA = ('Exporter');
@EXPORT = qw(create_frame);

use rlib '../../..';
use Devel::Trepan::CmdProcessor;
use Devel::Trepan::Interface::User;
use Devel::Trepan::Core;
use File::Basename qw(basename dirname);
use Devel::Trepan::Pod2Text qw(help2podstring);
use File::Spec;

package Devel::Trepan::CmdProcessor::Mock;
sub setup() {
    my $intf = Devel::Trepan::Interface::User->new;
    my $proc = Devel::Trepan::CmdProcessor->new([$intf], 'fixme');
    $proc;
}

sub create_frame() {
    my ($pkg, $file, $line, $fn) = caller(0);
    return [
	{
	    file      => $file,
	    fn        => $fn,
	    line      => $line,
	    pkg       => $pkg,
	}];
}

sub mock_subcmd_setup() {
    my ($pkg, $path) = caller(0);
    my $abs_path = File::Spec->rel2abs($path);
    my $parent_name = File::Basename::basename(
	File::Basename::dirname($abs_path));
    if ($parent_name =~ m{(\w)(\w+)_Subcmd}) {
	$parent_name = uc($1) . $2;
    }
    my $proc = Devel::Trepan::CmdProcessor->new;
    my $parent_pkg = "Devel::Trepan::CmdProcessor::Command::${parent_name}";
    my $parent = ${parent_pkg}->new($proc, lc $parent_name);
    my $cmd = ${pkg}->new($parent,
			  File::Basename::basename($path, '.pm'));
    my $help_text =
	Devel::Trepan::Pod2Text::help2podstring($cmd->{help},
						$proc->{settings}{highlight},
						$proc->{settings}{maxwidth});
    return $proc, $parent, $cmd, $help_text
}


if (__FILE__ eq $0) {
    my $proc=Devel::Trepan::CmdProcessor::Mock::setup;
    print $proc, "\n";
}

1;
