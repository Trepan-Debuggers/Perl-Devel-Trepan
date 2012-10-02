#!/usr/bin/env perl
use warnings; use strict;
use rlib '.'; use Helper; 
use English qw( -no_match_vars );
use Config;

if ($OSNAME eq 'MSWin32') {
    eval "use Test::More skip_all => 
     'We can not handle -e properly on Strawberry Perl'";
} elsif ( $Config{usesitecustomize} ) {
    eval "use Test::More skip_all => 
     'Site customization handles -e option differently'";
}
my $opts = {
    filter => sub{
	my ($got_lines, $correct_lines) = @_;
	my @result = ();
	for my $line (split("\n", $got_lines)) {
	    # Change lines like
	    #   main::(kZiu.pl:1) to 
	    #   main::(tempfile:1)
	    $line =~ s/main::\((?:.+):(\d+)\)/(tempfile.pl:$1)/;
	    push @result, $line;
	}

	$got_lines = join("\n", @result);
	return ($got_lines, $correct_lines);
    },
    run_opts => ' --basename --no-highlight -nx'
};

run_debugger("-e 'no warnings \"once\";\$x=1; \$y=2'", cmd_file(),
             undef, $opts);
done_testing();
