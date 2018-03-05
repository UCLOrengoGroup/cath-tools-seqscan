package Cath::Tools::CathVersion;

use Moo;

my %NAMED_RELEASES = (
  'latest'  => [4, 2],
  'current' => [9, 9, 9999],
);

has name  => ( is => 'ro', predicate => 'has_name' );
has major => ( is => 'ro', required => 1 );
has minor => ( is => 'ro', default => 0 );
has patch => ( is => 'ro', default => 0 );

sub new_from_string {
  my $class = shift;
  my $str = shift;

  my $name;
  my @parts;
  if ( exists $NAMED_RELEASES{ lc($str) } ) {
    $name = lc($str);
    @parts = @{ $NAMED_RELEASES{ lc($str) } };
  }
  else {
    my @parts = split /[\._]/, $str;
  }

  return __PACKAGE__->new(
    ( $name ? (name => $name) : () ),
    ( $parts[0] ? (major => $parts[0]) : () ),
    ( $parts[1] ? (minor => $parts[1]) : () ),
    ( $parts[2] ? (patch => $parts[2]) : () ),
  );
}

sub is_current {
  my $self = shift;
  return $self->name eq 'current';
}

sub to_string {
  my $self = shift;
  return $self->name if $self->is_current;
  sprintf( "%d.%d.%d", $self->major, $self->minor, $self->patch );
}

sub to_api_dir {
  my $self = shift;
  return $self->name if $self->is_current;
  sprintf( "v%d_%d_%d", $self->major, $self->minor, $self->patch );
}

1;
