#!/usr/bin/perl -w

# Copyright (c) 2002 Andrew J. Korty
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

# $Id: 11-get-info.t,v 1.3 2003/02/26 18:33:53 ajk Exp $

# Test for module roots

use strict;
use Test;

BEGIN { plan test => 5 }

use strict;
use File::Basename;
use File::Spec;
use MasonX::Resolver::CVS qw(CVS_SUFFIX);

my $repo = File::Spec->rel2abs('cvstest');

my $module1 = 'resolver/t';

my $file1 = basename __FILE__;
my $comp1 = File::Spec->catfile('', $file1);

ok my $resolver = MasonX::Resolver::CVS->new(
	cvs_module	=> $module1,
	cvs_repository	=> $repo
);
ok my $comp_source = $resolver->get_info($comp1);
ok $comp_source->last_modified ==
    (stat File::Spec->catfile('cvstest', $module1, $file1) . CVS_SUFFIX)[9];

ok open THIS, __FILE__;
my $this = join '', <THIS>;
close THIS;

ok &{$comp_source->{source_callback}} eq $this;
