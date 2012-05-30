package antilocal;

use strict;
use warnings;

use Data::Dumper;

our %vars;
sub import {
	my ($class, @symbols) = @_;

	my @caller = caller;
	_export($caller[0]);

	$^H{antilocals} = join(':', map { ($_, 1) } @symbols);

	foreach (@symbols) {
		$vars{$_} ||= $class->default_for_symbol($_);
  }
}

sub _export {
	my ($caller) = @_;
	no strict 'refs';
	no warnings 'redefine';
	*{"$caller\::antilocal"} = \&antilocal;
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

sub antilocal {
	my ($symbol) = @_;
	my @ci = caller(0);
	my $hh = $ci[10];
	return undef if ! defined $hh;
	my (%active) = split /:/, $hh->{antilocals};

	return $active{$symbol} ? $vars{$symbol} : undef;
}

1;
