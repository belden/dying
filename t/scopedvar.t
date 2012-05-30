#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;
use Test::Deep;

use lib '../lib';

{
	use scopedvar qw(@foo %bar);

	my $foo_ref = scopedvar('@foo');
	my $bar_ref = scopedvar('%bar');

	push @$foo_ref, qw(hello world);
	$bar_ref->{goodnight} = 'moon';

	my $another_foo = scopedvar('@foo');
	my $another_bar = scopedvar('%bar');

	cmp_deeply( $another_foo, [qw(hello world)] );
	cmp_deeply( $another_bar, {goodnight => 'moon'} );

	{
		my $yet_another_foo = scopedvar('%bar');
		cmp_deeply( $yet_another_foo, {goodnight => 'moon'} );
	}

	{
		no scopedvar '%bar';
		my $yet_another_foo = scopedvar('%bar');
		cmp_deeply( $yet_another_foo, undef );
	}

	{
		my $yet_another_foo = scopedvar('%bar');
		cmp_deeply( $yet_another_foo, {goodnight => 'moon'} );
	}
}

# my $yet_another_foo = scopedvar('%bar');
# cmp_deeply( $yet_another_foo, {goodnight => 'moon'} );
