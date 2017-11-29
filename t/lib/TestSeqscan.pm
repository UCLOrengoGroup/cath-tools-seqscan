package TestSeqscan;

use FindBin;
use Carp qw/ confess /;
use File::Temp qw/ tempdir /;

use lib "$FindBin::Bin/../extlib/lib/perl5";

use Moo;
use Path::Class;
use Bio::SeqIO;

use Cath::Tools::Seqscan;

has query_file => (
  is => 'ro',
  lazy => 1,
  builder => '_build_query_file',
);

sub _build_query_file {
  my $self = shift;
  my $test_script = $0;
  (my $expected_file = $test_script) =~ s/\.t$/.fa/;
  confess "! Error: failed to find expected query file `$expected_file` for test `$test_script`"
    unless -f $expected_file;
  return $expected_file;
}

has 'tmp_dir' => (
  is => 'ro',
  builder => '_build_tmp_dir',
  lazy => 1,
);

sub out_dir {
  my $self = shift;
  return dir( $self->tmp_dir );
}

sub _build_tmp_dir {
  return tempdir( CLEANUP => 1 );
}

has 'max_aln' => (
  is => 'ro',
  default => 1,
);

has 'app' => (
  is => 'ro',
  builder => '_build_app',
  lazy => 1,
  handles => [qw/ run /],
);

sub _build_app {
  my $self = shift;
  my $app = Cath::Tools::Seqscan->new(
    in  => $self->query_file,
    out => $self->tmp_dir,
    max_aln => $self->max_aln,
  );
  return $app;
}

sub parse_stockholm {
  my $self  = shift;
  my $aln_filename = shift;
  my $aln_file = $self->out_dir->file( $aln_filename );
  my $aln_fh = $aln_file->openr;

  my $seq_count=0;
  my %seqs_by_id;
  while ( my $line = $aln_fh->getline ) {
    next if $line =~ /^#/;
    last if $line =~ /^\//;
    my ($id, $seq) = split( /\s+/, $line );
    if ( exists $seqs_by_id{ $id } ) {
      $seqs_by_id{ $id }->{seq} .= $seq;
    }
    else {
      $seqs_by_id{ $id } = { id => $id, seq => $seq, order => $seq_count++ };
    }
  }
  return \%seqs_by_id;
}

1;
