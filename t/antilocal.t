#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 6;
use Test::Deep;

use lib '../lib';

{
	package somewhere;
	sub foo {
		use antilocal qw(@foo %bar);

		my $foo_ref = antilocal('@foo');
		my $bar_ref = antilocal('%bar');

		push @$foo_ref, qw(hello world);
		$bar_ref->{goodnight} = 'moon';

		my $another_foo = antilocal('@foo');
		my $another_bar = antilocal('%bar');

		main::cmp_deeply( $another_foo, [qw(hello world)] );
		main::cmp_deeply( $another_bar, {goodnight => 'moon'} );

		{
			my $yet_another_foo = antilocal('%bar');
			main::cmp_deeply( $yet_another_foo, {goodnight => 'moon'} );
		}

		{
			no antilocal '%bar';
			my $yet_another_foo = antilocal('%bar');
			main::cmp_deeply( $yet_another_foo, undef );
		}

		{
			my $yet_another_foo = antilocal('%bar');
			main::cmp_deeply( $yet_another_foo, {goodnight => 'moon'} );
		}
	}
}

sub blah {
	somewhere->foo;
	use antilocal ('%bar');
	my $yet_another_foo = antilocal('%bar');
	cmp_deeply( $yet_another_foo, {goodnight => 'moon'} );
}

blah();
