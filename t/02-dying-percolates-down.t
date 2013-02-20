#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 5;
use Test::Deep;

use lib '../lib';

# This sub says 'hey, I want old-school Perl dies in place, thanks!'
sub something_that_dies {
  use dying;
  use Carp ();
  die Carp::longmess "ack!";
}

# This poor sub simply calls some other sub that might die
my $value_after_die = "I won't get this return value because I already died";
sub wrapper {
  something_that_dies();
  return $value_after_die;
}

# quite clearly if we want to call wrapper(), we must eval { ... }
# (n.b. scoping here is to scope 'my $value')
{
  my $value = eval { wrapper() };
  is( $value, undef, "wrapper() called something that died before wrapper() could return its value" );
}

# Actually, since we're a higher call level than something_that_dies(), we can say 'no dying'
# and have that become the policy for all call levels below us.
{
  no dying;
  my $value = wrapper();
  is( $value, $value_after_die, "Got the return value we thought we'd \"never\" get" );
  ok( dying::died, 'we caught a die' );
}

# here's an example with different *scopes*
{
  my %values_at_level;

  {
    use dying;
    push @{$values_at_level{0}}, eval { wrapper() };       # no scope above us has said 'no dying', so we must eval this

    {
      no dying;
      push @{$values_at_level{1}}, wrapper();              # we've turned off dying for this scope and all lower ones.

      {
        use dying;
        push @{$values_at_level{2}}, eval { wrapper() };   # let's enable dying for this scope; better eval
      }

      use dying;
      push @{$values_at_level{1}}, eval { wrapper() } ;    # we've turned dying back on for this scope (and all lower ones), so we must eval here

      {
        no dying;
        push @{$values_at_level{2}}, wrapper();            # we've overridden our higher scopes' desire for normal perl dying, so no eval
      }

      {
        push @{$values_at_level{'2a'}}, eval { wrapper() };  # no higher scope has 'use dying' currently enabled, so eval
      }

      no dying;
      push @{$values_at_level{1}}, wrapper();              # once again our need for eval has gone away
    }

    push @{$values_at_level{0}}, eval { wrapper() };       # we never said 'no dying' at level 0, so always must eval
  }


  # stacks all end; time to test
  cmp_deeply( \%values_at_level, {
    0 => [(), ()],
    1 => [$value_after_die, (), $value_after_die],
    2 => [$value_after_die, ()],
    '2a' => [()],
  }, "scoping of 'use dying;' and 'no dying;' is correct" );
}


# and here's an example with different *call levels*
{
  my %values_at_level;

  sub {
    use dying;
    push @{$values_at_level{0}}, eval { wrapper() };       # no scope above us has said 'no dying', so we must eval this

    sub {
      no dying;
      push @{$values_at_level{1}}, wrapper();              # we've turned off dying for this scope and all lower ones.

      sub {
        use dying;
        push @{$values_at_level{2}}, wrapper();            # NOTE that even though we try to enable dying for this call level, a higher call level
      }->();                                               # has disabled dying: so we don't need to eval { ... } here.

      use dying;
      push @{$values_at_level{1}}, eval { wrapper() } ;    # we've turned dying back on for this scope (and all lower ones), so we must eval here

      sub {
        no dying;
        push @{$values_at_level{2}}, wrapper();            # we've overridden our higher scopes' desire for normal perl dying, so no eval
      }->();

      sub {
        push @{$values_at_level{'2a'}}, eval { wrapper() };  # no higher scope has 'use dying' currently enabled, so eval
      }->();

      no dying;
      push @{$values_at_level{1}}, wrapper();              # once again our need for eval has gone away
    }->();

    push @{$values_at_level{0}}, eval { wrapper() };       # we never said 'no dying' at level 0, so always must eval
  }->();


  # stacks all end; time to test
  cmp_deeply( \%values_at_level, {
    0 => [(), ()],
    1 => [$value_after_die, (), $value_after_die],
    2 => [$value_after_die, $value_after_die],
    '2a' => [()],
  }, "call stack behavior of 'use dying;' and 'no dying;' is correct" );
}
