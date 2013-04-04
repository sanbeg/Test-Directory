use Test::More tests => 2;
use lib '.';
use constant MODULE => 'Test::Directory';

use_ok(MODULE);

my $d='tmp-td';

my $td = MODULE->new($d, template=>'dsc_%0.4d.jpg');
is ($td->name(123), 'dsc_0123.jpg', 'template looks like camera file');
