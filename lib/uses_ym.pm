package uses_ym;

use strict;
use warnings;

sub import {
	shift;
	my $caller = caller;
	require ym;
	ym->import(@_);
	no strict 'refs';
	*{"$caller\::ym"} = \&ym::ym;
}

1;
