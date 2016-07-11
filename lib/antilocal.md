
=pod

# NAME

antilocal.pm - experimental Perl pragma to allow variables to flow *upwards* in the call stack

# SYNOPSIS

Sometimes you really just need safe global variables that only callers earlier than you in the
call stack may access. antilocal.pm provides that.

# DESCRIPTION

```
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

```
# LIMITATIONS

This only handles array and hash references as antilocal-able variables.

# BUGS

Funky code, tragically weird design pattern: you be the judge. Personally, I'm not ready to ship
this to production.

# AUTHOR

Belden Lyman <belden@cpan.org>

# LICENSE

You may use, distribute, and modify this under the same terms as Perl itself.


