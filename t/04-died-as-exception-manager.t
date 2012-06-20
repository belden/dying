#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 4;

no dying;
die 'oh no!';

is( died->ack, 1, 'acked one death' );
is_deeply( [died], [], 'nothing left to handle' );

die 'one';
die 'two';
is( died->ack, 2, 'acked two deaths' );

ok( ! died->ack, "nothing left to ack" );
