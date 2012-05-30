package antilocal;

use strict;
use warnings;

use Data::Dumper;

our %vars;
my $key = 0;

sub import {
	my ($class, @symbols) = @_;

	$^H{antilocals} = join(':', $key, map { ($_, 1) } @symbols);

	foreach (@symbols) {
		$vars{$key}{$_} = $class->default_for_symbol($_);
  }

	$key++;

	my $caller = caller;
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

	my ($key, $active) = split /:/, $^H{antilocals}, 2;
	$active =~ s{$_:1}{$_:0} foreach @symbols;
	$^H{antilocals} = join(':', $key, $active);
}

sub hinthash_for_call_level {
	my ($level) = @_;
	my @call_info = caller($level);
	return $call_info[10];
}

sub antilocal {
	my ($symbol) = @_;
	my $hh = hinthash_for_call_level(1);
	my ($key, %active) = split /:/, $hh->{antilocals};

	return $active{$symbol} ? $vars{$key}{$symbol} : undef;
}

1;