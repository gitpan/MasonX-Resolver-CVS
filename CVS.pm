# Copyright (c) 1999, 2000, 2001, 2002 Andrew J. Korty
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
# $Id: CVS.pm,v 1.9 2003/02/28 14:31:28 ajk Exp $

use strict;

package MasonX::Component::CVSBased;

use base 'HTML::Mason::Component::FileBased';

sub dir_path {
	my ($dir_path) = shift->{path} =~ m{(.*)/}s;
	$dir_path =~ s{/$}{} unless $dir_path eq '/';
	$dir_path;
}

sub name {
	my ($name) = shift->{path} =~ m{([^/]*)$}s;
	$name;
}

package MasonX::Resolver::CVS;

=head1 NAME

MasonX::Resolver::CVS - component path resolver for components in CVS

=head1 SYNOPSIS

  my $resolver = MasonX::Resolver::CVS->new(
  	cvs_module	=> 'cvs/module',
	cvs_repository	=> '/var/cvs'
  );
  my $info = $resolver->get_info('/some/comp.html');

=head1 DESCRIPTION

This L<HTML::Mason::Resolver(3)|HTML::Mason::Resolver(3)> subclass is
used when components are stored in the Concurrent Version System
(L<cvs(1)|cvs(1)>).  Currently, this subclass only supports local CVS
repositories.  As such, it is able to deliver component source without
checking the files out into a working directory (see
L<"IMPLEMENTATION NOTES">).

=cut

use constant CVS_PATH	=> '/usr/bin/cvs';
use constant CVS_SUFFIX	=> ',v';

use base qw(HTML::Mason::Resolver::File Exporter);

use File::Spec;
use HTML::Mason::ComponentSource;
use HTML::Mason::Exceptions (abbr => ['param_error']);
use HTML::Mason::Tools qw(read_file_ref);
use Params::Validate qw(:all);

@MasonX::Resolver::CVS::EXPORT_OK	= qw(CVS_PATH CVS_SUFFIX);
$MasonX::Resolver::CVS::VERSION	= '0.02';

__PACKAGE__->valid_params(
	cvs_module => {
		default	=> '',
		descr	=> 'CVS module where components reside',
		parse	=> 'list',
		type	=> SCALAR
	},
	cvs_repository => {
		default	=> '/var/cvs',
		descr	=> 'local CVS repository',
		parse	=> 'string',
		type	=> SCALAR
	}
);

=head1 PARAMETERS TO THE new() CONSTRUCTOR

The I<new> method takes two parameters, I<cvs_module> and
I<cvs_repository>.

=over 4

=item cvs_module

The I<cvs_module> attribute is a relative path that specifies the CVS
module that marks the top of your component hierarchy within the
repository.  For example, if I<cvs_module> is F<doc> and your CVS
repository is F</var/cvs>, a component path of F</products/index.html>
translates to the file F</var/cvs/doc/products/index.html,v>, which
will be checked out of CVS and processed by Mason.

The I<cvs_module> attribute defaults to the empty string, implying
that the URI space will be a direct mirror of the CVS hierarchy.  When
it is specified, it should be a relative filesystem path representing
the CVS module.

=item cvs_repository

The I<cvs_repository> attribute is an absolute pathname specifying the
local CVS repository.

=back

=cut

sub new {
	my $self = shift->SUPER::new(@_);

	# Ensure that module exists inside the repository

	param_error join '', "cvs_module '", $self->{cvs_module},
	    "' does not exist in the repository" unless -d $self->module_root;

	# Build comp_root attribute so we can use methods from the
	# File Resolver

	$self->{comp_root} = [[MAIN => $self->module_root]];

	$self;
}

# This method is used by the HTML::Mason::ApacheHandler class to
# translate web requests into component paths.

sub apache_request_to_comp_path {
	my ($self, $r) = @_;

	my $root = $self->module_root;

	my $file = File::Spec->catfile($root, $r->uri);
	$file .= $r->path_info unless -f $file . CVS_SUFFIX;

	my $path = substr $file, length $root;
	$path = length $path ? join '/', File::Spec->splitdir($path) : '/';
	chop $path if $path ne '/' && substr($path, -1) eq '/';

	$path;
}

# Return the contents of a component, in this case, a file in CVS.  We
# use "cvs checkout -p" to dump the contents to standard output rather
# than creating a file.

sub _get_source {
	my ($self, $path) = @_;
	open SOURCE, '-|' or exec CVS_PATH, '-Q',
	    -d => $self->{cvs_repository}, 'checkout', '-p', $path;
	my $source = join '', <SOURCE>;
	close SOURCE;
	$source;
}

# Given an absolute component path, returns a new
# HTML::Mason::ComponentSource object.  Since we only support a local
# repository, we cheat and look at the ,v files there.  The File
# Resolver does basically the same thing, so we call its get_info
# method and do a little translation.

sub get_info {
	my ($self, $path) = @_;
	my $comp_source = $self->SUPER::get_info($path . CVS_SUFFIX) or return;

	$comp_source->{comp_class} = 'MasonX::Component::CVSBased';
	$comp_source->{comp_path} = $path;
	my $cvs_file = File::Spec->abs2rel($comp_source->friendly_name,
	    $self->{cvs_repository}) or return;
	$cvs_file =~ s/@{[CVS_SUFFIX]}$//;
	$comp_source->{source_callback} =
	    sub { $self->_get_source($cvs_file) };

	$comp_source;
}

# The only argument to this method is a path glob pattern, something
# like ``/foo/*'' or ``/foo/*/bar''.  Given this pattern, it should
# return a list of component paths for components which match this
# glob pattern.  Again we cheat and match against the ,v files in the
# local repository.

sub glob_path {
	my ($self, $pattern) = @_;
	my %path_hash;
	my $root = $self->module_root;
	my @files = glob join '', $root, $pattern, CVS_SUFFIX;
	foreach my $file (@files) {
		next unless -f $file;
		$path_hash{substr $file, length $root, -length CVS_SUFFIX} = 1
		    if $root eq substr $file, 0, length $root;
	}
	keys %path_hash;
}

# Full path of the module in the CVS repository.

sub module_root {
	my $self = shift;
	File::Spec->canonpath(
		File::Spec->catfile(@$self{qw(cvs_repository cvs_module)})
	);
}

1;
__END__

=head1 IMPLEMENTATION NOTES

A L<HTML::Mason::Resolver(3)|HTML::Mason::Resolver(3)> class's
I<get_info> method must return an
L<HTML::Mason::ComponentSource(3)|HTML::Mason::ComponentSource(3)>
object that contains the last modification time of the component.
Since this module currently only supports local repositories, it just
goes into the repository and stats the file to get the last
modification time.

The best way I could find using CVS command to get the last
modification time is with C<cvs status>, which requires a checked out
working directory.  (The C<cvs history> command also returns the last
modification time, but it doesn't include the year.)  So if this
module is improved to support remote respositories, it will have to
keep checked out copies of the files.

=head1 BUGS

This implementation cheats by statting the modification dates of
repository files rather than using C<cvs status> or somesuch (see
L<"IMPLMEMENTATION NOTES">).  Consequently, Mason will think some
components have changed when they really haven't (e.g., a new revision
was checked in on a different branch).

This module forks to spawn CVS commands, which can be a waste of
resources, especially in a mod_perl environment.  In this version, CVS
commands are only run when the CVS file has changed.  Using a Perl
extension interface to a real CVS API would be an improvement, but the
author knows of no such API.

=head1 AUTHOR

Andrew J. Korty, <ajk@iu.edu>

=head1 SEE ALSO

L<HTML::Mason(3)|HTML::Mason(3)>,
L<HTML::Mason::ComponentSource(3)|HTML::Mason::ComponentSource(3)>,
L<HTML::Mason::Resolver(3)|HTML::Mason::Resolver(3)>

=cut
