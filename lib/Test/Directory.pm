package Test::Directory;

use strict;
use warnings;

use Carp;
use File::Spec;
use Test::Builder::Module;

our @ISA = 'Test::Builder::Module';

sub new {
    my $class = shift;
    my $dir = shift;
    my %opts = @_;

    if ($opts{unique}) {
	mkdir $dir or croak "$dir: $!";
    } else {
	mkdir $dir;
	croak "$dir: $!" unless -d $dir;
    };
    my %self = (dir => $dir);
    $self{template} = $opts{template} if defined $opts{template};
    bless \%self, $class;
}

sub clean {
    my $self = shift;
    foreach my $file ( keys %{$self->{files}} ) {
    	unlink $self->path($file);
    };
    rmdir $self->{dir};
}
    
sub count_unknown {
    my $self = shift;
    opendir my($dh), $self->{dir} or croak "$self->{dir}: $!";

    my %path = map {$self->name($_)=>$self->{files}{$_}} keys %{$self->{files}};
    my $count = 0;
    while (my $file = readdir($dh)) {
	next if $file eq '.';
	next if $file eq '..';
	next if $path{$file};
	++ $count;
    }
    return $count;
};

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

sub count_missing {
    my $self = shift;

    my $count = 0;
    while (my($file,$has) = each %{$self->{files}}) {
	++ $count if ($has and not(-f $self->path($file)));
    }
    return $count;
}

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

sub is_ok {
    my $self = shift;
    my $name = shift;
    my $test = $self->builder;

    my @miss;
    while (my($file,$has) = each %{$self->{files}}) {
	if ($has and not(-f $self->path($file))) {
	    push @miss, $file;
	}
    }

    opendir my($dh), $self->{dir} or croak "$self->{dir}: $!";

    my %path = map {$self->name($_)=>$self->{files}{$_}} keys %{$self->{files}};
    my @unknown;
    while (my $file = readdir($dh)) {
	next if $file eq '.';
	next if $file eq '..';
	next if $path{$file};
	push @unknown, $file;
    }

    my $rv = $test->is_num(@miss+@unknown, 0, $name);
    unless ($rv) {
	$test->diag("Missing: $_") foreach @miss;
	$test->diag("Unknown file: $_") foreach @unknown;
    }
    return $rv;
}


sub DESTROY {
    $_[0]->clean;
}

sub touch {
    my $self = shift;
    foreach my $file (@_) {
	open my($fh), '>', $self->path($file);
	$self->{files}{$file} = 1;
    };
};

sub create {
  my ($self, $file, %opt) = @_;
  my $path = $self->path($file);

  open my($fh), '>', $path or croak "$path: $!";
  $self->{files}{$file} = 1;

  if (defined $opt{content}) {
    print $fh $opt{content};
  };
  if (defined $opt{time}) {
    utime $opt{time}, $opt{time}, $path;
  };
  return $path;
}

sub remove_files {
  my $self = shift;
  my $count = 0;
  foreach my $file (@_) {
    my $path = $self->path($file);
    $self->{files}{$file} = 0;
    $count += unlink($path);
  }
  return $count;
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

sub name {
    my ($self,$file) = @_;
    return defined($self->{template})?
	sprintf($self->{template}, $file):
	$file;
};

sub path {
    my ($self,$file) = @_;
    File::Spec->catfile($self->{dir}, $self->name($file));
};

sub has {
    my ($self,$file) = @_;
    my $rv;
    if (-f $self->path($file)) {
      $rv = $self->{files}{$file} = 1;
    } else {
      $rv = $self->{files}{$file} = 0;
    }
    return $rv;
}

sub has_ok {
    my ($self,$file,$text) = @_;
    $self->builder->ok( $self->has($file), $text );
}

sub hasnt_ok {
    my ($self,$file,$text) = @_;
    $self->builder->ok( not($self->has($file)), $text );
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Test::Directory - Perl extension for maintaining test directories.

=head1 SYNOPSIS

 use Test::Directory
 use My::Module

 my $dir = Test::Directory->new($path);
 $dir->touch($src_file);
 My::Module::something( $dir->path($src_file) );
 $dir->has($src_file); #is source still there?
 $dir->has($dst_file); #did my module create dst?


=head1 DESCRIPTION

Sometimes, testing code involves making sure that files are created and
deleted as expected.  This module simplifies maintaining test directories by
tracking their status as they are modified or tested with this API, making
it simple to test both individual files, as well as verify that there are no
missing or unknown files.

There are two flavors of functions that examing the directory.  I<Utility>
functions simply return a count (i.e. the number of files/errors) with no
output, while the I<Test> functions use L<Test::Builder> to produce the
approriate test results and diagnostics for the test harness.

=head2 CONSTRUCTOR

=over

=item B<new>(I<PATH> [,I<OPTIONS>])

Create a new instance pointing to the specified I<PATH>. I<OPTIONS> is 
an optional hashref of options.

I<PATH> will be created it necessary.  If I<OPTIONS>->{unique} is set, it is
an error for <PATH> to already exist.

=back


=head2 UTILITY METHODS



=over

=item B<touch>(I<$file>)

Create the specified I<$file> and track its state.

=back

=head2 TEST METHODS

The test methods validate the state of the test directory, calling
L<Test::Builder>'s I<ok> and I<diag> methods to generate output.

=over

=item B<has>  (I<$file>, I<$test_name>)

=item B<hasnt>(I<$file>, I<$test_name>)

Verify the status of I<$file>, and update its state.  The test will pass if
the state is expected.

=item B<is_ok>(I<$test_name>)

Pass if the test directory has no missing or extra files.

=back

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Steve Sanbeg, E<lt>sanbeg@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Steve Sanbeg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
