package Cath::Tools::DomainBoundaryMapIO;

use Moo;
use FindBin;
use Carp qw/ croak /;
use Types::Standard qw/ :all /;

my $DEFAULT_MAPPING_FILE = "$FindBin::Bin/../data/domain-sequence-numbering.v4_1_0.txt.gz";

has 'fh' => (
  is => 'ro',
  isa => sub { $_->can('getline') },
);

sub next_domain {
  my $self = shift;
  my $fh = $self->fh;
  while( my $line = $fh->getline ) {
    next if $line =~ /^#/;
    my @cols = split( /\t/, $line );
    croak sprintf "! Error: expected 8 cols, found %d (line: $.)", scalar @cols;
    return Cath::Tools::DomainBoundaryMap->new(
      domain_id => $cols[0],
      # segment_count => $cols[1],
      atom_segments => $cols[2],
      atom_length => $cols[3],
      seqres_segments => $cols[4],
      seqres_length => $cols[5],
      expanded_seqres_segments => $cols[6],
      expanded_seqres_length => $cols[7],
    );
  }
  return;
}
