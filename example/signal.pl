use English qw( -no_match_vars );
my $leave_loop = 0;
sub hup_handler($)
{
    my $sig = shift;
    print "Got signal $sig in debugged program handler\n";
    $leave_loop = 1;
}
$SIG{'HUP'} = \&hup_handler;
my $tempfile;
if (1 == scalar @ARGV) { 
    $tempfile = $ARGV[0]
} else {
    $tempfile = "/tmp/signal.$$";
    print "My process is $$\n";
}
open(my $fh, '>', $tempfile) or die $OS_ERROR;
print $fh "$$\n";
close $fh;
until ($leave_loop) {
    sleep 1;
}
unlink $tempfile;
