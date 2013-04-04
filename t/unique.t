use Test::More tests => 5;
use Test::Exception;
use lib '.';
use constant MODULE => 'Test::Directory';

use_ok(MODULE);

my $d='tmp-td';
my $td1;

lives_ok { $td1 = MODULE->new($d, unique=>1) } "first unique lives";
dies_ok { MODULE->new($d, unique=>1) } "second unique dies";
dies_ok { $td1->create('.') } "Bogus file dies";

dies_ok { MODULE->new('README') } "Using plain file dies";
