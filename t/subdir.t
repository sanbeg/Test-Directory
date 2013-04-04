use Test::More;
use lib '.';
use constant MODULE => 'Test::Directory';

use_ok(MODULE);

my $d='tmp-td';

{
  my $td = MODULE->new($d);
  
  $td->mkdir('sd');
  $td->touch('sd/f1');
  
  $td->has_dir('sd');
  $td->hasnt_dir('od');
  $td->has('sd/f1');

  mkdir( $td->path('bogus-dir-1') );
  mkdir( $td->path('bogus-dir-2') );

  is ($td->count_unknown, 2, "2 unknown directory");
  $td->has_dir('bogus-dir-1');
  $td->rm_dir('bogus-dir-2');

  is ($td->name("a/b/c"), File::Spec->catfile('a','b','c'), "name contats");
}
ok (!-d($d), "dir was cleaned");


done_testing;
