package nodie;

use strict;
use warnings;

use Want qw(rreturn);
BEGIN { *CORE::GLOBAL::die = \&nodie }

sub import { $^H{nodie} = 1 }
sub unimport { $^H{nodie} = 0 }

sub nodie_in_effect {
	my $hinthash = (caller(1))[10];
	return $hinthash->{nodie};
}

sub nodie {
	if (nodie_in_effect()) {
		warn @_;
		rreturn undef;
	} else {
		CORE::die(@_);
	}
}

1;
