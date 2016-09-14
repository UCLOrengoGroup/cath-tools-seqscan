package Cath::Tools::DomainBoundaryMapIO;

use Moo;
use FindBin;
use Carp qw/ croak confess /;
use Types::Standard qw/ :all /;
use Cath::Tools::Types qw/ IdLookup /;
use IO::Uncompress::Gunzip qw/ $GunzipError /;
use Cath::Tools::DomainBoundaryMap;

has 'file' => (
  is => 'ro',
  isa => Str,
);

has filter_ids => (
  is => 'ro',
  isa => IdLookup,
  coerce => 1,
  predicate => 1,
);

has 'fh' => (
  is => 'ro',
  isa => sub { $_[0]->can('getline') },
  lazy => 1,
  builder => '_build_fh',
);

sub _build_fh {
  my $self = shift;
  my $file = $self->file;
  if ( $file =~ /\.gz$/ ) {
    (my $uncompressed_file = $file) =~ s/\.gz$//;
    if ( -e $uncompressed_file ) {
      $file = $uncompressed_file;
    }
  }
  my $fh = IO::Uncompress::Gunzip->new( $file )
    or die "Problem found with $file: $GunzipError";
  return $fh;
};

sub get_lookup {
  my $self = shift;
  my $fh = shift || $self->fh;

  my %domain_boundaries_by_id;

  my $filter_ids = $self->has_filter_ids ? $self->filter_ids : undef;

  LINE: while( my $line = $fh->getline ) {
    #warn "next_domain: $. $line";
    next if $line =~ /^#/;

    my @cols = split( /\t/, $line );

    confess sprintf( "! Error: expected 8 cols, found %d (line: $.)", scalar @cols )
      unless scalar @cols == 8;

    my $domain_id = $cols[0];

    if ( $filter_ids ) {
      #warn sprintf( "[%-6d] filter: %-50s %s %s\n",
      #  $., join(",", keys %$filter_ids), $domain_id, $filter_ids->{ $domain_id } ? 'YES' : 'NO' );
      next LINE unless exists $filter_ids->{ $domain_id };
    }

    my $dom = Cath::Tools::DomainBoundaryMap->new(
      domain_id => $domain_id,
      # segment_count => $cols[1],
      atom_segments => $cols[2],
      atom_length => $cols[3],
      seqres_segments => $cols[4],
      seqres_length => $cols[5],
      expanded_seqres_segments => $cols[6],
      expanded_seqres_length => $cols[7],
    );

    $domain_boundaries_by_id{ $dom->domain_id } = $dom;
  }

  return \%domain_boundaries_by_id;
}

1;
