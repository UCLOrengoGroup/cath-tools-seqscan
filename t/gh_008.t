use Test::More tests => 2;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestSeqscan;

my $app = TestSeqscan->new();

ok( $app->run, 'app runs okay' );

my $aln_file = "1.10.565.10-FF-338.sto";
my $seqs_by_id = $app->parse_stockholm( $aln_file );

my $seq_length;
my $seq_idx=0;
for my $seq ( sort { $a->{order} <=> $b->{order} } values %$seqs_by_id ) {
  $seq_length ||= length( $seq->{seq} );
  if ( length($seq->{seq}) != $seq_length ) {
    die sprintf( "! Error: length mismatch in sequence [%d] alignment file `$aln_file` (%d vs %d residues)", $seq_idx, $seq_length, length($seq->{seq}) );
  }
  $seq_idx++;
}

ok( 1, "All alignment lengths the same" );
