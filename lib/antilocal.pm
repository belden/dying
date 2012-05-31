package antilocal;

use strict;
use warnings;

use Data::Dumper;

our %vars;
sub import {
	my ($class, @symbols) = @_;

	$^H{antilocals} = join(':', map { ($_, 1) } @symbols);

	foreach (@symbols) {
		$vars{$_} ||= $class->default_for_symbol($_);
	}

	{
		my $i = 0;
		while (my $callpkg = caller($i++)) {
			_export($callpkg);
		}
	}
}

sub _export {
	my ($callpkg) = @_;
	no strict 'refs';
	no warnings 'redefine';
	*{"$callpkg\::antilocal"} = \&antilocal;
}

sub default_for_symbol {
	my ($class, $symbol) = @_;
	(my $type) = $symbol =~ m{^([@%])};
	CORE::die "can't figure a type for symbol: $symbol!" unless $type;
	return +{
		'@' => [],
		'%' => +{},
	}->{$type};
}

sub unimport {
	my ($class, @symbols) = @_;

	$^H{antilocals} =~ s{$_:1}{$_:0} foreach @symbols;
}

my %deeper_hinthash;
sub antilocal {
	my ($symbol) = @_;

	my $hinthash = (caller(0))[10];
	my $callsub = (caller(1))[3];

	if (! defined $hinthash) {
		$hinthash = $deeper_hinthash{$callsub || ''};
		return undef if ! defined $hinthash;
	} else {
		$deeper_hinthash{''} = $hinthash;
		my $i = 0;
		while (my @ci = caller($i++)) {
			$deeper_hinthash{$ci[3]} = $hinthash if ! $ci[10];
		}
	}
	my (%active) = split /:/, $hinthash->{antilocals};
	return $active{$symbol} ? $vars{$symbol} : undef;
}

1;
