package dying;

use strict;
use warnings;

our $VERSION = 0.01;
use Want qw(rreturn);
use Scalar::Util qw(refaddr);

BEGIN { *CORE::GLOBAL::die = \&mydie }

sub died {
  use antilocal qw(@died);
  my $died = antilocal('@died');
  my @died = grep { $_->is_active } @$died;

  my $trapping_die = trapping_die();
  return unless defined $trapping_die;

  return wantarray
    ? @died
    : dying::collection->new(@died);
}

sub died_with {
  use antilocal qw(@died);
  my $died = antilocal('@died');
  unshift @$died, dying::error->new(@_);
}

sub mydie {
  my $trapping_die = trapping_die();
  died_with(@_) if defined $trapping_die;
  if ($trapping_die) {
    rreturn undef;
  } else {
    CORE::die(@_);
  }
}

sub trapping_die {
  # Generally a pragma would just check (caller(1))[10]->{dying} here to see
  # if the caller wants the pragma to be in effect or not. We walk all the way up the
  # stack until we either (a) find proof someone higher than our caller has said
  # 'no dying', or (b) walk all the way off the call stack. "our caller" here means
  # "the code that has called die()" as opposed to "the code that said 'no dying'".
  #
  # N.B.: Once we find (a) we *don't* continue walking up the stack to see whether
  # some even more distant caller has *enabled* dying.
  my $i;
  my $no;
  while (my @ci = caller($i++)) {
    if (exists $ci[10]{dying}) {
      if ($ci[10]{dying}) {
        return 1;
      } else {
        $no = 0;
      }
    }
  }
  return $no;
}

{
  # when someone says 'use dying', they want dying to resume: make sure Carp::croak and ::confess are the real subs
  my %carp_import = (
    croak => \&Carp::croak,
    confess => \&Carp::confess,
  );

  # when someone says 'no dying', they want dying to stop: replace Carp::croak and ::confess with \&mydie
  my %carp_unimport = (
    croak => \&mydie,
    confess => \&mydie,
  );

  sub _swap_carp_diers_around {
    my (%subs_to_swap_in) = @_;
    my $caller = caller(1);

    no strict 'refs';
    no warnings 'redefine';
    my %stash = %{"$caller\::"};
    foreach (qw(croak confess)) {
      *{"$caller\::$_"} = $subs_to_swap_in{$_} if exists $stash{$_} && refaddr(\&{"$caller\::$_"}) == refaddr(\&{"Carp\::$_"});
      *{"Carp\::$_"} = $subs_to_swap_in{$_};
    }
  }

  sub import {
    $^H{dying} = 0;
    _swap_carp_diers_around(%carp_import);
    _mega_export();
  }

  sub unimport {
    $^H{dying} = 1;
    _swap_carp_diers_around(%carp_unimport);
    _mega_export();
  }
}

sub _mega_export {
  my $i = 0;
  while (my @c = caller($i++)) {
    next if $c[0] eq __PACKAGE__;
    no strict 'refs';
    no warnings 'redefine';
    *{"$c[0]\::died"} = \&died;
  }
}

{
  package dying::collection;

  use strict;
  use warnings;

  use overload (
    '0+' => sub { @{shift()} },
    fallback => 1,
  );

  sub new {
    my $class = shift;
    return bless [@_], $class;
  }

  sub ack { return map { $_->ack } @{shift()} }
}

{
  package dying::error;

  use strict;
  use warnings;
  require Time::HiRes;

  sub new {
    my ($class, @error) = @_;

    my @callstack;
    my $i = 1; # start at 1 rather than 0 so dying::error->new doesn't appear
    while (my @callinfo = caller($i++)) {
      push @callstack, [map { ref($_) eq 'HASH' ? +{%$_} : $_ } @callinfo];
    }

    local $" = ' ';
    return bless {
      error => "@error",
      time => Time::HiRes::time(),
      callstack => \@callstack,
      state => 'active',
    }, $class;
  }

  sub error { shift->{error} }
  sub ack { shift->{state} = 'acknowledged' }
  sub is_active { shift->{state} eq 'active' }
}

1;

__END__

=pod

=head1 NAME

dying - Perl pragma to prevent your code from dying

=head1 DESCRIPTION

Free yourself from the unwanted burden of calling other code inside C<eval> blocks!
Make your code stop crashing, and allow it to continue running in a possibly insane state!
Play with an experimental exception module disguised as a legitimate pragma!

=head1 SYNOPSIS

You do not need to C<use dying;> in order to use C<dying>. All Perl code by default runs with C<use dying;> enabled - that is,
calling die() in normal Perl code prints a message to STDERR and causes your program to terminate execution. (See also: C<perldoc -f die>.)

If you want your code to stop dying, now you can simply write:

=over 4

  no dying;

=back

at the appropriate place, and code run within the same scope *or lower* will not be allowed to die. When you're ready to allow code to
die again, you simply add

=over 4

  use dying;

=back

at the appropriate place. If you scope your calls to C<no dying;> to the lexical scope that's causing you grief, you don't need to
bother with the C<use dying;>.

=head1 APOLOGY

C<die> gets used in two different ways by Perl programmers:

=over 4

=item 1. To terminate program execution when an invalid state has been reached.

=item 2. As an assertion system to message failure back to a caller.

=back

For example, consider this code:

=over 4

  sub open_a_fh {
      my ($file) = @_;
      open my $fh, '>', $file or die "$file: $!\n";
      return $fh;
  }

=back

It looks like we're dying because we've hit an invalid state. Especially if our corresponding caller looks like so:

=over 4

  my $fh = open_a_fh('/tmp/my-log.txt');
  print $fh "here's some message I care about\n";

=back

However, a caller might look like this:

=over 4

  sub choose_a_log_fh {

      foreach my $possible_log_file (qw(/tmp/here /tmp/there /tmp/anywhere)) {
          my $fh = open_a_fh($possible_log_file);
          return $fh if defined $fh;
      }

      return \*STDERR;
  }

  my $fh = choose_a_log_fh();
  print $fh "here's some message I care about\n";

=back

In this case, the die() in open_a_fh() is now a design decision that we need to actively work against. We must guard against
the die() by changing choose_a_log_fh() like so:

=over 4

  sub choose_a_log_fh {

      foreach my $possible_log_file (qw(/tmp/here /tmp/there /tmp/anywhere)) {
          my $fh = eval { open_a_fh($possible_log_file) };
          return $fh if defined $fh;
      }

      return \*STDERR;
  }

=back

The C<eval> has the effect of telling Perl that some subordinate piece of code might die, and that we don't actually want Perl
to obey that directive. Instead, Perl should set up errors in some accessible place for us to check at our convenience.

There's actually no onus on the Perl programmer to go and look for those errors, nor to handle them meaningfully. Consequently,
the die-on-error design decision, which was intended to provoke thoughtful error handling (or complete program termination, in
the case where we aren't using an C<eval>), serves only to place a strange interface burden upon all callers: namely, "You must
call open_a_fh() in an eval even if you don't care about the errors it may throw."

C<dying> makes it easy to signal to Perl that C<die> is a suggestion to be ignored. The above example can simply be changed like
so:

=over 4

  sub choose_a_log_fh {

      foreach my $possible_log_file (qw(/tmp/here /tmp/there /tmp/anywhere)) {
          no dying;                                    # de-escalate die() to warn()
          my $fh = open_a_fh($possible_log_file);
          return $fh if defined $fh;
      }

      return \*STDERR;
  }

=back

If you want to check whether a death occured, you may use C<died>:

=over 4

  sub choose_a_log_fh {

      foreach my $possible_log_file (qw(/tmp/here /tmp/there /tmp/anywhere)) {
          no dying;
          my $fh = open_a_fh($possible_log_file);
          died->ack if died;                           # we've "handled this error" by trying other files.
          return $fh if defined $fh;
      }

      return \*STDERR;
  }

=back

=head1 POLICY ON DYING

This module provides two related policies for handling C<die>: reporting, and de-escalation. In both cases, any call to
C<die> while this module is in effect will result in the C<died> function being populated with meaningful data regarding
exceptions.

Note that selecting either the reporting or de-escalation policy will make the C<died> function available to your current
call stack and all those that are higher, and will report on or de-escalate deaths within your current call stack and
all those that are lower.

=head2 POLICY: REPORTING

The most basic use of this module is to simply say

=over 4

  use dying;

=back

With C<use dying;> in effect, calls to C<die> actually will die in the standard fashion. This means you will need to
C<eval> any code which may die, just as you normally would.

The added behavior from C<use dying;> is that assertion objects are stored in an L<antilocal> location, and may be later
retrieved and acknowledged or rethrown. Additionally, if your program terminates with any unacknowledged exceptions, they
will present their full details to STDERR when your program exits.

=head2 POLICY: DE-ESCALATION

You may de-escalate assertions from deaths to warnings by simply adding

=over 4

  no dying;

=back

to your program. When C<dying> is not in effect, your Perl program will not be allowed to C<die>. Instead, deaths are
reported in the same fashion as the reporting policy, and your program's execution continues.

Note that the function which attempted to C<die> will return undef to its caller.

=head1 SCOPING

Unlike other pragmata, which are lexically scoped simply to the current lexical level, C<dying> affects your current lexical
scope and all lower scopes. This means that once you select a policy, either by importing or unimporting C<dying>, any attempt
to C<die> in your current scope or any subroutine you call within that scope will result in your selected policy being enforced.

As previously noted, C<died> gets exported all the way back up your call stack. Ideally, the C<died> that gets exported all the
way up would be localised only to the environment that imports or unimports C<dying>. That is, given this code:

=over 4

     1    #!/usr/bin/env perl
     2
     3    use Hither;
     4
     5    Hither::quack_safely();
     6

Nothing exciting yet. We've loaded a module and called a function.

     7    package Hither;
     8
     9    use Somewhere;
    10
    11    sub quack_safely {
    12        my $jail = Somewhere->new;
    13        $jail->safe_method_call('quack');
    14    }
    15

We've created an object and called a method on it; still tame.

    16    package Somewhere;
    17
    18    sub safe_method_call {
    19        my ($self, $method, @args) = @_;
    20        no dying;
    21        my @return_values = $self->$method(@args);
    22        return died->ack ? () : @return_values;
    23    }
    24
    25    sub quack { die 'quack' }

And here's our safe_method_call. It simply disables dying and dispatches the requested method.

=back

Line 20 has three effects:

=over 4

=item 1. It prevents code from dying.

The fatal call to $self->$method (wherein $method = 'quack') will not actually die. Instead, the caller of $self->$method
(i.e. line 20 itself) will receive undef from its failed attempt to call ->quack.

=item 2. It ensures you'll know your code died.

The die() at line 25 will not go unreported. If the program being executed reaches its termination point without line 25's
assertion being acknowledged, the program will produce a stack trace from point of execution to point of assertion.

=item 3. It exports died() to this call frame and all others above it.

Line 20 makes the died() function available to Somewhere::safe_method_call, Hither::quack_safely, and main. No other call
frames may access died() - even within the namespaces of Somewhere::, Hither::, and main::. This surprising bit of scoping
is accomplished via C<antilocal>, see which.

=back

=head1 EXPORTS

=over 4

=item * C<died>

Answers the age-old question, "Did the code that I just trapped die?". In scalar context, returns the count of assertions
that have been trapped for your current call level. In list context, returns the actual assertion objects themselves.

=back

=cut
