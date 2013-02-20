NAME
====
dying - Perl pragma to prevent your code from dying

DESCRIPTION
===========
Free yourself from the unwanted burden of calling other code inside
`eval' blocks! Make your code stop crashing, and allow it to continue
running in a possibly insane state! Play with an experimental exception
module disguised as a legitimate pragma!

SYNOPSIS
========
You do not need to `use dying;' in order to use `dying'. All Perl code
by default runs with `use dying;' enabled - that is, calling die() in
normal Perl code prints a message to STDERR and causes your program to
terminate execution. (See also: `perldoc -f die'.)

If you want your code to stop dying, now you can simply write:

```perl
no dying;
```

at the appropriate place, and code run within the same scope *or lower*
will not be allowed to die. When you're ready to allow code to die
again, you simply add

```perl
use dying;
```

at the appropriate place. If you scope your calls to `no dying;' to the
lexical scope that's causing you grief, you don't need to bother with
the `use dying;'.

APOLOGY
=======
`die' gets used in two different ways by Perl programmers:

1. To terminate program execution when an invalid state has been
reached.
2. As an assertion system to message failure back to a caller.

For example, consider this code:

```perl
sub open_a_fh {
    my ($file) = @_;
    open my $fh, '>', $file or die "$file: $!\n";
    return $fh;
}
```

It looks like we're dying because we've hit an invalid state. Especially
if our corresponding caller looks like so:

```perl
my $fh = open_a_fh('/tmp/my-log.txt');
print $fh "here's some message I care about\n";
```

However, a caller might look like this:

```perl
sub choose_a_log_fh {

    foreach my $possible_log_file (qw(/tmp/here /tmp/there /tmp/anywhere)) {
        my $fh = open_a_fh($possible_log_file);
        return $fh if defined $fh;
    }

    return \*STDERR;
}

my $fh = choose_a_log_fh();
print $fh "here's some message I care about\n";
```

In this case, the die() in open_a_fh() is now a design decision that we
need to actively work against. We must guard against the die() by
changing choose_a_log_fh() like so:

```perl
sub choose_a_log_fh {

    foreach my $possible_log_file (qw(/tmp/here /tmp/there /tmp/anywhere)) {
        my $fh = eval { open_a_fh($possible_log_file) };
        return $fh if defined $fh;
    }

    return \*STDERR;
}
```

The `eval' has the effect of telling Perl that some subordinate piece of
code might die, and that we don't actually want Perl to obey that
directive. Instead, Perl should set up errors in some accessible place
for us to check at our convenience.

There's actually no onus on the Perl programmer to go and look for those
errors, nor to handle them meaningfully. Consequently, the die-on-error
design decision, which was intended to provoke thoughtful error handling
(or complete program termination, in the case where we aren't using an
`eval'), serves only to place a strange interface burden upon all
callers: namely, "You must call open_a_fh() in an eval even if you don't
care about the errors it may throw."

`dying' makes it easy to signal to Perl that `die' is a suggestion to be
ignored. The above example can simply be changed like so:

```perl
sub choose_a_log_fh {

    foreach my $possible_log_file (qw(/tmp/here /tmp/there /tmp/anywhere)) {
        no dying;                                    # de-escalate die() to warn()
        my $fh = open_a_fh($possible_log_file);
        return $fh if defined $fh;
    }

    return \*STDERR;
}
```

If you want to check whether a death occured, you may use `died':

```perl
sub choose_a_log_fh {

    foreach my $possible_log_file (qw(/tmp/here /tmp/there /tmp/anywhere)) {
        no dying;
        my $fh = open_a_fh($possible_log_file);
        died->ack if died;                           # we've "handled this error" by trying other files.
        return $fh if defined $fh;
    }

    return \*STDERR;
}
```

POLICY ON DYING
===============
This module provides two related policies for handling `die': reporting,
and de-escalation. In both cases, any call to `die' while this module is
in effect will result in the `died' function being populated with
meaningful data regarding exceptions.

Note that selecting either the reporting or de-escalation policy will
make the `died' function available to your current call stack and all
those that are higher, and will report on or de-escalate deaths within
your current call stack and all those that are lower.

POLICY: REPORTING
-----------------
The most basic use of this module is to simply say

```perl
use dying;
```

With `use dying;' in effect, calls to `die' actually will die in the
standard fashion. This means you will need to `eval' any code which may
die, just as you normally would.

The added behavior from `use dying;' is that assertion objects are
stored in an antilocal location, and may be later retrieved and
acknowledged or rethrown. Additionally, if your program terminates with
any unacknowledged exceptions, they will present their full details to
STDERR when your program exits.

POLICY: DE-ESCALATION
---------------------
You may de-escalate assertions from deaths to warnings by simply adding

```perl
no dying;
```

to your program. When `dying' is not in effect, your Perl program will
not be allowed to `die'. Instead, deaths are reported in the same
fashion as the reporting policy, and your program's execution continues.

Note that the function which attempted to `die' will return undef to its
caller.

SCOPING
=======
Unlike other pragmata, which are lexically scoped simply to the current
lexical level, `dying' affects your current lexical scope and all lower
scopes. This means that once you select a policy, either by importing or
unimporting `dying', any attempt to `die' in your current scope or any
subroutine you call within that scope will result in your selected
policy being enforced.

As previously noted, `died' gets exported all the way back up your call
stack. Ideally, the `died' that gets exported all the way up would be
localised only to the environment that imports or unimports `dying'.
That is, given this code:

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

And here's our safe_method_call. It simply disables dying and
dispatches the requested method.

Line 20 has three effects:

1. It prevents code from dying.
  The fatal call to $self->$method (wherein $method = 'quack') will
  not actually die. Instead, the caller of $self->$method (i.e. line
  20 itself) will receive undef from its failed attempt to call
  ->quack.

2. It ensures you'll know your code died.
  The die() at line 25 will not go unreported. If the program being
  executed reaches its termination point without line 25's assertion
  being acknowledged, the program will produce a stack trace from
  point of execution to point of assertion.

3. It exports died() to this call frame and all others above it.
  Line 20 makes the died() function available to
  Somewhere::safe_method_call, Hither::quack_safely, and main. No
  other call frames may access died() - even within the namespaces of
  Somewhere::, Hither::, and main::. This surprising bit of scoping is
  accomplished via `antilocal', see which.

EXPORTS
=======
* `died'

  Answers the age-old question, "Did the code that I just trapped
  die?". In scalar context, returns the count of assertions that have
  been trapped for your current call level. In list context, returns
  the actual assertion objects themselves.
