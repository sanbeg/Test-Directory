use Test::More;
use lib '.';
use constant MODULE => 'Test::Directory';

use_ok(MODULE);

my $d='tmp-td';

{
  my $td = MODULE->new($d);
  
  $td->mkdir('sd');
  $td->touch('sd/f1');
  
  $td->has_directory('sd');
  $td->hasnt_directory('od');
  $td->has('sd/f1');
}
ok (!-d($d), "dir was cleaned");

done_testing;
