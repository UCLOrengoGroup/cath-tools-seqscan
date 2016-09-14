package Cath::DomainBoundaryMap;

use Moo;
use Cath::Segment;

has domain_id => (
  is => 'ro',
  isa => 'Str',
  required => 1,
);

has atom_segments => (
  is => 'ro',
  isa => 'ArrayRef[Cath::Segment]',
  default => sub { [] },
);

has seqres_segments => (
  is => 'ro',
  isa => 'ArrayRef[Cath::Segment]',
  default => sub { [] },
);

has expanded_seqres_segments => (
  is => 'ro',
  isa => 'ArrayRef[Cath::Segment]',
  default => sub { [] },
);


1;
