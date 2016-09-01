package Cath::Search::Utils;

use Cath::Moose;
use Carp qw/ croak confess /;
use Bio::LocatableSeq;
use File::Temp;
use IPC::Run qw/ run timeout /;
use namespace::autoclean;

my $GAP_CHAR = '-';

sub align_sequence_to_hmm {
  my (%params) = validated_hash(\@_,
    hmm_lib     => { isa => File, coerce => 1 },
    hmm_aln_bp  => { isa => 'Bio::Align::AlignI' },
    hmm_id      => { isa => 'Str' },
    query       => { isa => 'Str' },
    trim        => { isa => 'Bool', default => 0 },
    outformat   => { isa => 'Str', default => 'Stockholm' },
  );

  croak "! Error: failed to find HMM lib file `$params{hmm_lib}`"
    unless -f $params{hmm_lib};

  # sort query file
  my ($query_fh, $query_file) = tempfile();
  $query_fh->print( $params{query} );

  # fetch hmm file
  my ($hmm_fh, $hmm_file) = tempfile();
  {
    my @cmd = ( "hmmfetch", "-o", $hmm_file, $params{hmm_lib}, $params{hmm_id} );
    my ($stdin, $stdout, $err);
    run \@cmd, \$stdin, \$stdout, \$err, timeout(10)
      or confess "! Error: failed to execute `".join(" ", @cmd)"`: $?";
    die "! Error: hmmfetch failed to create `$hmm_file` (cmd: `".join(" ", @cmd)."`)"
      unless -s $hmm_file > 0;
  }

  my $aln_file = 't/search_hsp_align.3.30.70.330_42762.fa';
  my $hmm_file = '';

  my $command = join( " ", "hmmalign", "--mapali  tmp.hmm tmp.fa" );
  Bio::AlignIO->new( -file => " |", -format => 'Stockholm' );

}

sub add_hsp_to_align {
  my (%params) = validated_hash(\@_,
    bio_align => { isa => 'Bio::Align::AlignI' },
    hsp => { isa => 'Cath::Search::HSP' },
    query_name => { isa => 'Str', optional => 1 },
  );

  my $aln = $params{bio_align};
  my $hsp = $params{hsp};
  my $query_name = $params{query_name} || 'QUERY';

  my $query_string = $hsp->query_string;
  my $hit_string   = $hsp->hit_string;
  my $query_start  = $hsp->query_start;
  my $query_end    = $hsp->query_end;
  my $hit_start    = $hsp->hit_start;
  my $hit_end      = $hsp->hit_end;
  my $hsp_length   = length( $query_string );

  my @aln_seqs = map { $_->seq } $aln->each_seq;
  my @aln_ids  = map { $_->id }  $aln->each_seq;
  my $aln_count = scalar @aln_seqs;

  # fill the alignment with gaps before the hsp
  warn sprintf "Adding %d GAPs to start of query\n", $hit_start - 1;
  my $aligned_query_string = $GAP_CHAR x ($hit_start - 1);

  for ( my $hsp_idx = 0; $hsp_idx < $hsp_length; $hsp_idx++ ) {
    my $query_res = substr( $query_string, $hsp_idx, 1 );
    my $query_offset = $query_start + $hsp_idx;
    my $hit_res = substr( $hit_string, $hsp_idx, 1 );
    my $hit_offset = $hit_start + $hsp_idx;

    #warn "HSP [$hsp_idx]: $query_res ($query_offset)    $hit_res ($hit_offset)\n";

    if ( $query_res eq $GAP_CHAR ) {
      # don't think we need to do anything here...
      # (the "query" sequence in the hsp already has gaps)
    }

    if ( $hit_res eq $GAP_CHAR ) {
      # add gap in the alignment
      warn "Adding GAP in alignment at position $query_offset\n";
      for (my $seq_idx = 0; $seq_idx < $aln_count; $seq_idx++) {
        substr( $aln_seqs[ $seq_idx ], $query_offset, 0, $GAP_CHAR );
      }
    }

    $aligned_query_string .= $query_res;
  }

  my $new_aln_length = length( $aln_seqs[0] );

  $aligned_query_string .= $GAP_CHAR x ( $new_aln_length - length($aligned_query_string) );
  warn "$aligned_query_string\n";

  my $new_aln = $aln->new;
  my $query_seq = Bio::LocatableSeq->new(
    -id => $query_name,
    -seq => $aligned_query_string,
    -start => $query_start,
    -end => $query_end
  );
  $new_aln->add_seq( $query_seq );
  for (my $seq_idx = 0; $seq_idx < $aln_count; $seq_idx++) {
    my $new_seq = Bio::LocatableSeq->new( -id => $aln_ids[ $seq_idx ], -seq => $aln_seqs[ $seq_idx ] );
    $new_aln->add_seq( $new_seq );
  }
  return $new_aln;
}

1;
