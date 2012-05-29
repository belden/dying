package scopedvar;

use strict;
use warnings;

# use scopedvar '@foo';
# if (grep { 1 } scopedvar('@foo')) { print "saw a 1" }
sub import {
	my ($class, @symbols) = @_;

	foreach (@symbols) {
		$^H{symbols}{$_} = 1;
    $class->ready($_);
  }

	my $caller = caller;
	no strict 'refs';
	no warnings 'redefine';
	*{"$caller\::scopedvar"} = \&scopedvar;
}

# no scopedvar '@foo';
sub unimport {
	my ($class, @symbols) = @_;
	foreach (@symbols) {
    # $class->unready($_);
		delete $^H{symbols}{$_};
  }
}

sub ready {
	my ($class, $symbol) = @_;
	my $hh = hinthash_for_call_level(2);
	(my $type) = $symbol =~ m{^([@$%])};
	CORE::die "can't figure a type for symbol: $symbol!" unless $type;
	my $default = +{
		'@' => [],
		'%' => +{},
		'$' => undef,
	}->{$type};
	$hh->{$symbol} = $default;
}

sub hinthash_for_call_level {
	my ($level) = @_;
	my @call_info = caller($level);
	return $call_info[10];
}

sub scopedvar {
	my ($symbol) = @_;
	return hinthash_for_call_level(2)->{$symbol};
}

1;
