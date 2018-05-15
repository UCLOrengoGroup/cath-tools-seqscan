use Test::More tests => 3;

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use TestSeqscan;

my $uniprot_acc = 'P00520';
my $expected_length = 1123;
my $app = TestSeqscan->new( uniprot => $uniprot_acc );
ok( $app->run, 'app runs okay' );

my $aln_file = "1.10.510.10-FF-79024.sto";
my $seqs_by_id = $app->parse_stockholm( $aln_file );

my $found_domain = 0;
for my $seq ( values %$seqs_by_id ) {
  if ( $seq->{id} =~ m{P00520\|ABL1_MOUSE} ) {
    $found_domain = 1;
    my $seq = $seq->{seq};
    # get rid of white space and gaps
    $seq =~ s/\s+//mg;
    $seq =~ s/[.\-]//mg;
    is( length($seq), $expected_length, 'sequence info matches sequence length' );
  }
}

ok( $found_domain, "Found expected domain in alignment file" );
