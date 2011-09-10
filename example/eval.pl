$var = '
$x = 2;
$y = 3;
$z = 4';
eval $var;
$eval_sub='
sub five() {
    my @args = @_;
    print "ho\n";
    5;
}';
eval $eval_sub;
$y = five();
print "$y\n";
