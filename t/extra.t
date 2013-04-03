#! /usr/bin/perl -w

use Test::More;
use lib '.';
use constant MODULE => 'Test::Directory::Extra';

use_ok(MODULE);

my $d='tmp-td';
my $td = MODULE->new($d);
$td->touch(1,2);


$td->missing_ok("no missing files");
$td->unknown_ok("no unknown files");

done_testing;
