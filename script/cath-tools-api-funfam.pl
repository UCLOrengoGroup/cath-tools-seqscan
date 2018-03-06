#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use Config;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../extlib/lib/perl5";
use lib "$FindBin::Bin/../extlib/lib/perl5/$Config{archname}";

use Log::Any::Adapter ('Stdout');

use Cath::Tools::Api::Funfam;

my $app = Cath::Tools::Api::Funfam->new_with_options();

$app->run;
