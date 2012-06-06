package dying;

use strict;
use warnings;

our $VERSION = 0.01;
use Want qw(rreturn);
use Data::Dumper;

BEGIN {
	*CORE::GLOBAL::die = \&mydie;

	# require Carp;
	# no warnings 'redefine';

	# my $build_handler = sub {
	# 	my ($if, $else) = @_;
	# 	return sub { goto &{ trapping_die() ? $if : $else } };
	# };

	# my $orig_croak = \&Carp::croak;
	# *Carp::croak = $build_handler->(
	# 	sub { died_with(@_); Carp::carp(@_); rreturn undef },
	# 	$orig_croak,
	# );

	# my $orig_confess = \&Carp::confess;
	# *Carp::confess = $build_handler->(
	# 	sub { died_with(@_); Carp::cluck(@_); rreturn undef },
	# 	$orig_confess,
	# );
}

sub mydie {
	died_with(@_);
	if (trapping_die()) {
		rreturn undef;
	} else {
		CORE::die(@_);
	}
}

sub trapping_die {
	# Generally a pragma would just check (caller(1))[10]->{trapping_die} here to see
	# if the caller wants the pragma to be in effect or not. We walk all the way up the
	# stack until we either (a) find proof someone higher than our caller has said
	# 'no dying', or (b) walk all the way off the call stack. "our caller" here means
	# "the code that has called die()".
	#
	# N.B.: Once we find (a) we *don't* continue walking up the stack to see whether
	# some even more distant caller has *enabled* dying. This asymmetry is probably
	# surprising, and if you've read this comment and want this code to behave differently
	# please do let me know. My decision here is fairly arbitrary.
	my $i;
	my $no;
	while (my @ci = caller($i++)) {
		if (exists $ci[10]{trapping_die}) {
			return 1 if $ci[10]{trapping_die};
		} else {
      $no = 1;
    }
	}
	return $no;
}

sub import {
	$^H{trapping_die} = 0;
	_install_die_handler();
	_mega_export();
}

sub unimport {
	$^H{trapping_die} = 1;
	# _install_die_handler();
	_mega_export();
}


{
	my @died;
	sub died {
		return trapping_die()
			? wantarray
				? @died
				: scalar @died
			: 0;
	}
	sub died_with { unshift @died, [@_] };
}

# my $orig = $SIG{__DIE__} || sub {};
sub _install_die_handler {
	$SIG{__DIE__} = sub { died_with(@_) if trapping_die() };
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

=item 1. To terminate program execution, as in the venerable "open() or die()"

=item 2. To message failure back to a caller.

=back

die() also gets used as a messaging system for handleable exceptions in code. For example, consider this code:

=over 4

  sub open_a_fh {
    my ($file) = @_;
    open my $fh, '>', $file or die "$file: $!\n";
		return $fh;
  }

=back

And a corresponding caller:

=over 4

  my $fh = open_a_fh('/tmp/my-log.txt');
  print $fh "here's some message I care about\n";

=back

In this case, the die() in open_a_fh() looks reasonable; if we can't open the target file we die. However, a caller might look
like this:

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

In this case, the die() in open_a_fh() is now a design decision that we need to actively work against. We guard against the die()
by changing choose_a_log_fh() like so:

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

=cut
