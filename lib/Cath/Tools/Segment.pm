package Cath::Tools::Segment;

use Moo;
use Types::Standard qw/ :all /;

has start => (
  is => 'ro',
  isa => Str,
  required => 1,
);

has stop => (
  is => 'ro',
  isa => Str,
  required => 1,
);

sub to_string {
  my $self = shift;
  return join( "-", $self->start, $self->stop );
}

1;
