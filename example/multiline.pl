sub foo {
    my $a = 0; $a += 10; $a *= 20;
    for (my $i=1; $i < 2; $i++)  {
	print $i, "\n";
    }
    return $a if $a > 10;
    return 0;
}

sub fib($) {
    my $x = shift;
    return 1 if $x <= 1;
    return(fib($x-1) + fib($x-2))
}

foo();
my $x = 0; $x += 1; $x *= 2;
my $z = 1;
printf "fib(2)= %d, fib(3) = %d, fib(4) = %d\n", fib(2), fib(3), fib(4);
