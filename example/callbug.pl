sub iamok {
   print "iamok\n";
}
sub iamnotok {
   no warnings qw(uninitialized);
   print "iamnotok\n";
}
if (scalar @ARGV) {
        iamnotok(@ARGV);
} else {
        iamok();
}
