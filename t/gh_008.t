use Test::More tests => 5;

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../extlib/lib/perl5";

use Path::Class;
use Bio::SeqIO;
use File::Temp qw/ tempdir /;

use_ok( 'Cath::Tools::Seqscan' );

my $tmp_dir = tempdir( CLEANUP => 0 );

my $app = Cath::Tools::Seqscan->new(
  in  => "$FindBin::Bin/gh_008.fa",
  out => $tmp_dir,
  max_aln => 1,
  no_cache => 1,
);

isa_ok( $app, 'Cath::Tools::Seqscan' );

diag( "tmp_dir: $tmp_dir" );

ok( $app->run, 'app runs okay' );

my $aln_file = dir( "$tmp_dir" )->file( "1.10.565.10-FF-338.fasta" );

ok( -e $aln_file, "alignment file `$aln_file` exists" );

my $fh = $aln_file->open;

my $seqio = Bio::SeqIO->new( -file => $aln_file, -format => 'fasta' );

my $seq_length;
my $seq_idx=0;
while( my $seq = $seqio->next_seq ) {
  $seq_length ||= $seq->length;
  if ( $seq->length != $seq_length ) {
    die sprintf( "! Error: length mismatch in sequence [%d] alignment file `$aln_file` (%d vs %d residues)", $seq_idx, $seq_length, $seq->length );
  }
  $seq_idx++;
}

ok( 1, "All alignment lengths the same" );
