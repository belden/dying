use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME                => 'dying',
  AUTHOR              => q{Belden Lyman <belden@cpan.org>},
  VERSION_FROM        => 'lib/dying.pm',
  ABSTRACT            => 'experimental Perl pragma for exceptions',
  LICENSE => 'perl',
  META_MERGE => {
    resources => {
        bugtracker => 'http://github.com/belden/dying/issues',
        homepage => 'http://github.com/belden/dying',
        repository => 'git://github.com/belden/dying.git',
    },
  },
  PREREQ_PM => {
    'Test::More' => 0,
    'Test::Deep' => 0,
  },
  PL_FILES            => {},
  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
