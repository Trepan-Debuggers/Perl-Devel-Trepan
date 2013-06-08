package Devel::Trepan::DB::Use;
use File::Basename; use File::Spec;

BEGIN {
    unshift @INC, \&use_hook;
};

sub use_hook {
    my ($coderef, $filename) = @_; # $coderef is \&my_sub
    ## FIXME: allow for calling the debugger on "use".
    # print "++use_hook ", $filename, "\n";
    if ($filename eq 'SelfLoader.pm') {
	my $dirname = dirname(__FILE__);
	my $SelfLoader_file = File::Spec->catfile($dirname, 'SelfLoader.pm');
	no strict 'refs';
	open(FH, '<', $SelfLoader_file) or return undef;
	return *FH;
    }
    return undef
}

1;
