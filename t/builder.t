use Test::More tests=>16;
use Test::Builder::Tester;
use lib '.';
use Test::Directory;
use strict;

my $tmp = 'tmp-td';
my $td = Test::Directory->new($tmp);
$td->touch(1);

test_out("ok 1 - first");
$td->has(1, 'first');
test_test('has existing file is true');

test_out("ok 1 - Has file 1.");
$td->has(1);
test_test('has existing file is true, default text');


test_out("not ok 1 - first");
test_fail(+1);
$td->hasnt(1, 'first');
test_test('hasnt existing file is false');

test_out("not ok 1 - Doesn't have file 1.");
test_fail(+1);
$td->hasnt(1);
test_test('hasnt existing file is false, default text');


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

do {
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
};

# sub directory tests
test_out("ok 1 - Doesn't have directory no-dir.");
$td->hasnt_dir("no-dir");
test_test("no dir");

test_out("ok 1 - no-dir");
$td->hasnt_dir("no-dir", "no-dir");
test_test("no dir");

$td->mkdir('sub-dir');
test_out("ok 1 - Has directory sub-dir.");
$td->has_dir('sub-dir');
test_test('sub-dir, def text');

test_out("ok 1 - Has sub-dir");
$td->has_dir('sub-dir', 'Has sub-dir');
test_test('sub-dir, +text');


test_out('ok 1 - clean');
$td->clean_ok('clean');
test_test('clean is OK');

do {
  my $td = Test::Directory->new("$tmp-rename");
  $td->touch('miss');
  $td->mkdir('miss-d');

  rename($td->path('miss'), $td->path('extra')) or die;
  rmdir($td->path('miss-d'));

  test_out('not ok 1 - rename');
  test_fail(+2);
  test_diag('Missing file: miss', 'Missing directory: miss-d','Unknown file: extra');
  $td->is_ok('rename');
  test_test('rename is not OK');

  rename($td->path('extra'), $td->path('miss')) or die;
};

do {
  my $td = Test::Directory->new("$tmp-dirs");
  $td->mkdir('miss-d');
  $td->mkdir('d');
  $td->check_directory('gone');

  mkdir $td->path('extra-d');

  rmdir($td->path('miss-d'));
  open my($fh), '>', $td->path('miss-d');

  test_out('not ok 1 - dir to file');
  test_fail(+2);
  test_diag('Missing directory: miss-d','Unknown file: extra-d');
  $td->is_ok('dir to file');
  test_test('dir to file is not OK');

  unlink $td->path('miss-d');
  rmdir $td->path('extra-d');
}
