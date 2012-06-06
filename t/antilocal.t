#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 7;
use Test::Deep;

use lib '../lib';

blah();
my $another_copy_altogether = antilocal('%bar');
cmp_deeply( $another_copy_altogether, {goodnight => 'moon'} );

sub blah {
	somewhere->foo;
	my $yet_another_foo = antilocal('%bar');
	cmp_deeply( $yet_another_foo, {goodnight => 'moon'} );
}

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
