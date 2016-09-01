#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../extlib/lib/perl5";

use Cath::Tools::Seqscan;

my $app = Cath::Tools::Seqscan->new_with_options();

$app->run;
