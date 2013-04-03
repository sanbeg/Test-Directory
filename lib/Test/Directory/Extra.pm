package Test::Directory::Extra;
use base 'Test::Directory';
use Carp;

sub unknown_ok {
    my $self = shift;
    my $name = shift;

    opendir my($dh), $self->{dir} or croak "$self->{dir}: $!";

    my %path = map {$self->name($_)=>$self->{files}{$_}} keys %{$self->{files}};
    my @unknown;
    while (my $file = readdir($dh)) {
	next if $file eq '.';
	next if $file eq '..';
	next if $path{$file};
	push @unknown, $file;
    }

    my $test = $self->builder;
    my $rv = $test->is_num(scalar(@unknown), 0, $name);
    if (@unknown) {
	$test->diag("Unknown file: $_") foreach @unknown;
    }
    return $rv;
};


sub missing_ok {
    my $self = shift;
    my $name = shift;
    my $test = $self->builder;

    my @miss;
    while (my($file,$has) = each %{$self->{files}}) {
	if ($has and not(-f $self->path($file))) {
	    push @miss, $file;
	}
    }

    my $rv = $test->is_num(scalar(@miss), 0, $name);
    if (@miss) {
	$test->diag("Missing: $_") foreach @miss;
    }
    return $rv;
}

sub remove_ok {
  my ($self, $file, $test_name) = @_;
  my $path = $self->path($file);

  $self->{files}{$file} = 0;

  my $rv = $self->builder->ok(unlink($file), $test_name||"removed $file");
  unless ($rv) {
    $self->builder->diag("$path: $!");
  }
  return $rv;
}

1;
