#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 8;

use lib '../lib';

my $died;
$SIG{__DIE__} = sub { $died = 1 };

# here's eval-as-exception-handler
{
  local *died;
  local $@;

  my $knell = "I can trap this die() via the surrounding eval { ... }";
  eval { die $knell };

  like( $@, qr/\Q$knell\E/ );
  is( $died, 1 );
}

# here's us just not dying
{
  local *died;
  local $@;

  my $knell = "I can trap this die() in a different fashion altogether";
  no dying;
  die $knell;

  my @d = dying::died;
  ok( @d == 1, 'we died once' );
  like( $d[0]->error, qr/\Q$knell\E/, "we can find our death knell" );
  is( $died, 1, "\$SIG{__DIE__} got hit" );
  is( $@, undef, "We aren't implemented in terms of an eval" );
}

# scope of 'no dying' ends; default Perl dying is back in effect
eval { die "last stop" };
like( $@, qr/last stop/, "we have to eval our die() when 'no dying' is not in effect" );
is( $died, 1 );
