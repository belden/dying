#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 13;
use Test::Differences ();

use lib '../lib';

sub deep_ok ($$;$) {
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  Test::Differences::unified_diff;
  Test::Differences::eq_or_diff(@_);
}

# $@ doesn't have your death messages; died() does.
{
  package lame::one;

  sub go {

    local $@;
    eval { die "setting \$@\n" };

    no dying;
    die "here I am in lame::one\n";

    main::ok( died, 'we died' );
    main::deep_ok( [map { $_->error } died], [["here I am in lame::one\n"]], "in 'no dying;' context, found the die" );
    main::is( $@, "setting \$@\n", 'we left $@ untouched' );
    died->ack;
    main::deep_ok( [map { $_->error } died], [], 'nothing active after acking' );
  }
}

# If you explicitly 'use dying;' then you may choose to look at died() rather than $@
{
  package lame::too;

  sub go {
    use dying;

    main::deep_ok( [map { $_->error } died], [], 'nothing active in test-block start' );

    eval { die "here I am in lame::too\n" };
    main::is( died, 1,"we've died once" );
    main::deep_ok( [map { $_->error } died], [["here I am in lame::too\n"]], 'died() contains expected exceptions' );
    main::is( $@, "here I am in lame::too\n", '$@ is still set' );

    eval { die "here's another message\n" };
    main::is( died, 2,"we've died twice" );
    main::is( $@, "here's another message\n", 'clobbered $@ (boo)' );
    main::deep_ok( [map { $_->error } died], [["here's another message\n"], ["here I am in lame::too\n"]], 'all assertions available' );
  }
}

lame::one->go;
is( died, undef, 'no dies after scope end' );
lame::too->go;
is( died, undef, 'no dies after scope end' );
