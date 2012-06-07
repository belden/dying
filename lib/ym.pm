package ym;

our %vars;
sub import {
	my ($class, @ymbols) = @_;

	my %active = split /:/, $^{ym} || '';

	foreach (@ymbols) {
		my ($type) = $_ =~ m{^([@%])};
		next unless $type;

		$active{$_} = 1;
		$vars{$_} = +{
			'@' => [],
			'%' => {},
		}->{$type};
	}

	$^H{ym} = join ':', %active;

	my %seen;
	my $i = 0;
	while (my $callpkg = caller($i++)) {
		next if $seen{$callpkg}++;
		*{"$callpkg\::ym"} = \&ym;
	}
}

sub ym {
	my ($symbol) = @_;
	return $vars{$symbol};
}

1;
__END__

=head1 NAME

ym.pm - pragma to make variables move backwards in time.

=head1 DESCRIPTION

Regular software development is a straightfoward process akin to making a sweater with a tangled ball
of yarn and knitting needles; you find an entry point, a design, and get cracking. If you're practicing
TDD then perhaps you try on the ball of yarn first, then decide to knit a sweater. Every now and then
your business decisions pivot and force you to want a different weight of yarn in the armpits, or a nice
zipper down the middle, so you painstakingly pick out the bits you don't want and add in those you now do.

Adding the pragma C<ym.pm> to your development cycle makes things more fun, because it turns your ball of yarn
into a ball of wax, and steals your knitting needles leaving you only with your disbelief and that one old
chopstick that you've never bothered pulling out of your filing cabinet.

And really, who doesn't want a nice chance to go through and clean house every now and then? C<ym.pm> gives
you ample reason to want to do that. Not figuratively; literally: you will power down your computer, tell
your boss you've come down with a violent case of the chills, and go home to mop floors and wash mirrors:
anything to avoid coming back to your code again.

=head1 SYNOPSIS

=over 4

  use ym qw(@ym);             # declare our intent to have an antiarray named @ym
  my $ym = ym('@ym');         # grab our antiarray
  push @$ym, 'my my my';      # make *1* assignment to the antiarray

  print scalar(@$ym), "\n";   # 2. Wait, what?!

  foreach (@$ym) {
    print "$_\n";
  }
  __END__
  2
  my my my
  my my my

=back

=head1 CONWAY'S IMPLEMENTATION

When I saw Damian Conway's QuaQuackversal Hypnotistic Physics Lecture cum Crazy Perl talk, I figured he'd
just had a very nice troll of NY.pm. Har har, very funny Dr. Conway. Variables that move backwards through
time indeed. His implementation of the above toy script would look something like this:

=over 4

  ym @ym;                   # declare our intent to have an antiarray named @ym

  print scalar(@ym), "\n";  # 1. Wait, what?!

  foreach (@ym) {
    print "$_\n";
  }

  push @ym, 'my my my';

  __END__
  1
  my my my

=back

Clearly Conway's antivariables are superior to those found herein, since what only happens once in
Conway's universe still only happens once - the result of something having happened is simply available
before it's been done.

In this implementation of C<ym.pm>, what happens once unfortunately happens twice: once before you've
gone and done it, and once when you actually go and do it. The nice bit is you can still find out
what you are going to have done before your program hits that point of execution.

=head1 HOW IT WORKS

I have very little insight to offer you here. This was an accidental implementation that fell out of
my experimental C<antilocal.pm> (which, as the name implies, makes variables visible in this lexical
scope and in all B<higher> ones - as opposed to C<local>), which itself is a requirement for my
even more experimental C<dying.pm> (which strives to change how C<die> works in Perl so it produces
findable - not catchable - exceptions). Somewhere along the way this poor implementation of ym fell
out and on the floor, where probably should have stepped on it.

=head1 SERIOUSLY HOW IT WORKS

Read the code, it's pretty well explained there.

=head1 AUTHOR

Belden Lyman <belden@cpan.org>

=head1 COPYRIGHT AND LICENSE AND BIG SHOUTY WORDS

(c) 2012 Belden Lyman.

This is free software. You may use, modify, distribute, and jeer at it under the same terms as Perl
itself.

AS I PROMISED HERE ARE SOME BIG SHOUTY WORDS ABOUT HOW UNFIT THIS CODE IS FOR ROCKET CONTROL, SELF-
DRIVING AUTOMOBILES, AND ESPECIALLY LITTLE ONE-LINERS YOU WRITE AT THE COMMAND LINE. At the same time,
here's a more reasoned sentence that claims you might find this useful to understand how to implement
pragmatic modules in Perl, or to learn about the various phases of Perl's compile- and run-time, and
how they can be coerced to interact rather strangely with one another. MORE SHOUTY WORDS I PRETTY
MUCH LIKE TYPING WITH CAPS LOCK ON!!!
