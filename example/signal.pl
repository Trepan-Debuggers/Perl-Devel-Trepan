use English
my $leave_loop = 0;
sub hup_handler($)
{
    my $sig = shift;
    print "Got signal $sig\n";
    $leave_loop = 1;
}
$SIG{'HUP'} = \&hup_handler;
print "My process is $$\n";
my $tempfile = "/tmp/signal.$$";
open(my $fh, '>', $tempfile) or die $OS_ERROR;
print $fh "$$\n";
close $fh;
until ($leave_loop) {
    sleep 1;
}
unlink $tempfile;
