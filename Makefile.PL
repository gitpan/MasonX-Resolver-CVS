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
# $Id: Makefile.PL,v 1.1 2003/02/25 13:26:42 ajk Exp $

use ExtUtils::MakeMaker;

# MakeMaker's libscan ignores CVS directories, and well it should.
# Unfortunately, it also ignores CVS.pm.

sub MY::libscan {
	package MY;
	my ($self, $path) = @_;
	return $path if $path =~ /CVS\.pm$/;
	$self->SUPER::libscan($path);
}

# Earlier versions of the following modules may work fine.  If so,
# please notify the author! :-)

my %prereq = (
	HTML::Mason		=> 1.18,
	File::Spec		=> 0.82,
	Params::Validate	=> 0.51
);

WriteMakefile(
	NAME		=> 'MasonX::Resolver::CVS',
	VERSION_FROM	=> 'CVS.pm',
	PREREQ_PM     	=> \%prereq
);
