use Test::More;
use Test::Builder::Tester;
use lib '.';
use Test::Directory;

my $td = Test::Directory->new('tmp-td');
$td->touch(1);

test_out("ok 1 - first");
$td->has(1, 'first');
test_test('first');

test_out("ok 1 - empty");
$td->is_ok("empty");
test_test('empty');

done_testing();
