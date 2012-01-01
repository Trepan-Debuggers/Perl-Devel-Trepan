my $leave_loop = 0;
sub hup_handler($)
{
    my $sig = shift;
    print "Got signal $sig\n";
    $leave_loop = 1;
}
$SIG{'HUP'} = \&hup_handler;
print "My process is $$\n";
until ($leave_loop) {
    sleep 1;
}
