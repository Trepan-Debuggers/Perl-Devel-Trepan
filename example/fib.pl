sub fib($) {
    my $x = shift;
    return 1 if $x <= 1;
    fib($x-1) + fib($x-2);
}

printf "fib(2)= %d, fib(3) = %d, fib(4) = %d\n", fib(2), fib(3), fib(4);
