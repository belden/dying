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

__END__

=pod

=head1 NAME

antilocal.pm - experimental Perl pragma to allow variables to flow *upwards* in the call stack

=head1 SYNOPSIS

Sometimes you really just need safe global variables that only callers earlier than you in the
call stack may access. antilocal.pm provides that.

=head1 DESCRIPTION

=over 4

  #!/usr/bin/perl

  use strict;
  use warnings;          # there's nothing up my sleeves

  Somewhere::Else->do_something();
  my $stashed = antilocal('%stashed');  # go find the antilocal variable named '%stashed'
	while (my ($key, $value) = each %$stashed) {
    print "$key => $value\n";
  }

  exit 0;

  BEGIN {
    package Somewhere::Else;

    use strict;
    use warnings;

    sub do_something {
			my ($class) = @_;
      $class->prepare;
    }

    sub prepare {
			my ($class) = @_;
      $class->validate;
    }

    sub validate {
			my ($class) = @_;

      use antilocal '%stashed';
      my $stashed = antilocal('%stashed');
      $stashed->{$_} = $_ + 100 foreach 1..10;
    }
  }

=back

=head1 LIMITATIONS

This only handles array and hash references as antilocal-able variables.

=head1 BUGS

Funky code, tragically weird design pattern: you be the judge. Personally, I'm not ready to ship
this to production.

=head1 AUTHOR

Belden Lyman <belden@cpan.org>

=head1 LICENSE

You may use, distribute, and modify this under the same terms as Perl itself.

=cut
