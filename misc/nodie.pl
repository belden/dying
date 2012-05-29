#!/usr/bin/env perl

use strict;
use warnings;

use lib '.';
use nodie;

die "this is not a death!";

no nodie;
die "exiting via death!";
print "exiting\n";
