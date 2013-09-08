#!perl
use strict;
use warnings;
sub problem {
    $SIG{__DIE__} = sub {
	die "<b problem> will set a break point here.\n"
    };
    warn "This line will run even if you enter <c problem>.\n";
}

problem();
exit(0);
