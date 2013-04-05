use Test::More tests=>8;
use Test::Builder::Tester;
use lib '.';
use Test::Directory;

my $tmp = 'tmp-td';
my $td = Test::Directory->new($tmp);
$td->touch(1);

test_out("ok 1 - first");
$td->has(1, 'first');
test_test('has existing file is true');

test_out("not ok 1 - first");
test_fail(+1);
$td->hasnt(1, 'first');
test_test('hasnt existing file is false');

test_out('not ok 1 - second');
test_fail(+1);
$td->has(2, 'second');
test_test('has bogus file is false');

test_out('ok 1 - second');
$td->hasnt(2, 'second');
test_test('hasnt bogus file is true');

test_out("ok 1 - empty");
$td->is_ok("empty");
test_test('empty');

open my($fh), '>', "$tmp/xxx";
test_out("not ok 1 - empty");
test_fail(+2);
test_diag('Unknown file: xxx');
$td->is_ok("empty");
test_test('not empty');
close $fh;

test_out('not ok 1 - clean');
test_fail(+1);
$td->clean_ok('clean');
test_test('clean with extra file files');

unlink "$tmp/xxx";

test_out('ok 1 - clean');
$td->clean_ok('clean');
test_test('clean is OK');
