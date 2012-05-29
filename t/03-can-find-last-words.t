#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 4;

use lib '../lib';

# $@ doesn't have your death messages; died() does.
{
	package lame::one;

	local $@;
	eval { die "setting \$@\n" };

	no dying;
	die "here I am\n";

	main::ok( died, 'we died' );
	main::is_deeply( [died], [["here I am\n"]], "in 'no dying;' context, found the die" );
	main::is( $@, "setting \$@\n", 'we left $@ untouched' );
}

# If you explicitly 'use dying;' then you may choose to look at died() rather than $@
{
	package lame::too;

	use dying;
	eval { die "here I am\n" };

	main::is( died, 1,"we've died once" );
	main::is_deeply( [died], [["here I am\n"]] );
	main::is( $@, "here I am\n" );

	eval { die "here's another message\n" };
	main::is( died, 2,"we've died twice" );
	main::is_deeply( [died], [["here's another message\n"], ["here I am\n"]] );
	main::is( $@, "here's another message\n" );
}
