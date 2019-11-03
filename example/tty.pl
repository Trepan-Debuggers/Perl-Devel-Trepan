#!/usr/bin/perl
my $slave_tty_name = shift;
my $master_tty_name;
($master_tty_name = $slave_tty_name) =~ s/pts/tty/;

my $MAST = $master_tty_name;
my $SLAV = $slave_tty_name;

my $pid = fork();
if ( $pid ) {
    #  parent
    open(MASTOUT, "+>$SLAV") || die "Cannot open $SLAV to MASTOUT, aborted";
    close($MAST);
    select(MASTOUT); $| = 1;
    select(STDOUT); $| = 1;
    waitpid($pid, 0);
} else {
    # child
    open(MASTIN, "+<$SLAV") || die "Cannot ope $SLAV to MASTIN, aborted";
    close($MAST);
    while ($mastin = <MASTIN>) {
	print STDOUT "$$: $mastin";
    }
    exit(0);
}
