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

sub ok {
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
    if (-f $self->path($file)) {
	$self->{files}{$file} = 1;
	return 1;
    } else {
	$self->{files}{$file} = 0;
	return 0;
    }
}

sub has_ok {
    my ($self,$file,$text) = @_;
    ok( $self->has($file), $text );
}

sub hasnt_ok {
    my ($self,$file,$text) = @_;
    ok( not($self->has($file)), $text );
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

=head2 CONSTRUCTOR

=over

=item B<new>(I<PATH> [,I<OPTIONS>])

Create a new instance pointing to the specified I<PATH>. I<OPTIONS> is 
an optional hashref of options.

I<PATH> will be created it necessary.  If I<OPTIONS>->{unique} is set, it is
an error for <PATH> to already exist.

=back

=head2 METHODS



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

steve, E<lt>steve@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by steve

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
