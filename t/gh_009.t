use Test::More tests => 5;

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use TestSeqscan;

my $app = TestSeqscan->new();
ok( $app->run, 'app runs okay' );

my $aln_file = "1.10.565.10-FF-338.sto";
my $seqs_by_id = $app->parse_stockholm( $aln_file );

my $found_domain = 0;
for my $seq ( values %$seqs_by_id ) {
  if ( $seq->{id} =~ m{2jfaA00/([0-9]+)\-([0-9]+)} ) {
    my ($start, $stop) = ($1, $2);
    $found_domain = 1;
    is( $start, 24,  "Start looks okay" );
    is( $stop, 252, "Stop looks okay" );
    my $seq = $seq->{seq};
    # get rid of white space and gaps
    $seq =~ s/\s+//mg;
    $seq =~ s/[.\-]//mg;
    my $expected_length = $stop - $start + 1;
    is( length($seq), $expected_length, 'segment info matches sequence length' );
  }
}

ok( $found_domain, "Found domain in alignment file" );
