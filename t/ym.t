#!/usr/bin/env perl

use strict;
use warnings;

use uses_ym qw(@ym);             # declare our intent to have an antiarray named @ym
my $ym = ym('@ym');         # grab our antiarray
push @$ym, 'my my my';      # make *1* assignment to the antiarray

print scalar(@$ym), "\n";		# 2. Wait, what?!

foreach (@$ym) {
	print "$_\n";
}
__END__
