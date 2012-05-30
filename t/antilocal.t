#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;
use Test::Deep;

use lib '../lib';

{
	use antilocal qw(@foo %bar);

	my $foo_ref = antilocal('@foo');
	my $bar_ref = antilocal('%bar');

	push @$foo_ref, qw(hello world);
	$bar_ref->{goodnight} = 'moon';

	my $another_foo = antilocal('@foo');
	my $another_bar = antilocal('%bar');

	cmp_deeply( $another_foo, [qw(hello world)] );
	cmp_deeply( $another_bar, {goodnight => 'moon'} );

	{
		my $yet_another_foo = antilocal('%bar');
		cmp_deeply( $yet_another_foo, {goodnight => 'moon'} );
	}

	{
		no antilocal '%bar';
		my $yet_another_foo = antilocal('%bar');
		cmp_deeply( $yet_another_foo, undef );
	}

	{
		my $yet_another_foo = antilocal('%bar');
		cmp_deeply( $yet_another_foo, {goodnight => 'moon'} );
	}
}

# my $yet_another_foo = antilocal('%bar');
# cmp_deeply( $yet_another_foo, {goodnight => 'moon'} );
