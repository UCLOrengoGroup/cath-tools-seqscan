package Cath::Tools::DomainBoundaryMap;

use Moo;
use Types::Standard qw( :all );
use Cath::Tools::Types qw/ ArrayOfSegments /;

has domain_id => (
  is => 'ro',
  isa => Str,
  required => 1,
);

has atom_segments => (
  is => 'ro',
  isa => ArrayOfSegments,
  coerce => 1,
  default => sub { [] },
);

has atom_length => (
  is => 'ro',
  isa => Num,
);

has seqres_segments => (
  is => 'ro',
  isa => ArrayOfSegments,
  coerce => 1,
  default => sub { [] },
);

has seqres_length => (
  is => 'ro',
  isa => Num,
);

has expanded_seqres_segments => (
  is => 'ro',
  isa => ArrayOfSegments,
  coerce => 1,
  default => sub { [] },
);

has expanded_seqres_length => (
  is => 'ro',
  isa => Num,
);

sub atom_segments_str { _segs_as_string( $_[0]->atom_segments ) };
sub seqres_segments_str { _segs_as_string( $_[0]->seqres_segments ) };
sub expanded_seqres_segments_str { _segs_as_string( $_[0]->expanded_seqres_segments ) };

sub _segs_as_string {
  my $segs = shift;
  return join( ',', map { $_->to_string } @$segs );
}

1;
