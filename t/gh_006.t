use Test::More tests => 3;

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../extlib/lib/perl5";

use File::Temp qw/ tempdir /;

use_ok( 'Cath::Tools::Seqscan' );

my $tmp_dir = tempdir( CLEANUP => 1 );

my $app = Cath::Tools::Seqscan->new(
  in  => "$FindBin::Bin/gh_006.fa",
  out => $tmp_dir,
);

isa_ok( $app, 'Cath::Tools::Seqscan' );

ok( $app->run, 'app runs okay' );
