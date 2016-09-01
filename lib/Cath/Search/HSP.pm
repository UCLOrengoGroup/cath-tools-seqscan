package Cath::Search::HSP;

=head1 NAME

Cath::Search::HSP - abstracts Bio::Search::HSP::HSPI

=head1 SYNOPSIS

  $hsp->evalue;
  $hsp->frac_identical;
  $hsp->frac_conserved;
  $hsp->query_string;
  $hsp->hit_string;
  $hsp->homology_string;
  $hsp->algorithm;
  $hsp->length;
  $hsp->rank;
  $hsp->score;
  $hsp->hit_start;
  $hsp->hit_end;
  $hsp->query_start;
  $hsp->query_end;

=cut

use Cath::Moose;
use Cath::Types;
use MooseX::Storage;
use namespace::autoclean;

with Storage();
with 'Cath::Role::HasMetaData';

around 'BUILDARGS' => sub {
  my $orig = shift;
  my $class = shift;
  my $args = scalar @_ == 1 ? $_[0] : { @_ };

  $args->{hit_start} = delete $args->{match_start}
    if defined $args->{match_start};

  $args->{hit_end} = delete $args->{match_end}
    if defined $args->{match_end};

  return $class->$orig( %$args );
};

has 'evalue'           => ( is => 'ro', isa => 'Num', required => 1 );
has 'frac_identical'   => ( is => 'ro', isa => 'Num', required => 0 );
has 'frac_conserved'   => ( is => 'ro', isa => 'Num', required => 0 );
has 'query_string'     => ( is => 'ro', isa => 'Str', required => 1 );
has 'hit_string'       => ( is => 'ro', isa => 'Str', required => 1 );
has 'homology_string'  => ( is => 'ro', isa => 'Str', required => 1 );
has 'algorithm'        => ( is => 'ro', isa => 'Str', required => 0 );
has 'length'           => ( is => 'ro', isa => 'Num', required => 1 );
has 'rank'             => ( is => 'ro', isa => 'Num', required => 1 );
has 'score'            => ( is => 'ro', isa => 'Num', required => 1 );

has 'hit_start'        => ( is => 'ro', isa => 'Str', required => 1 );
has 'hit_end'          => ( is => 'ro', isa => 'Str', required => 1 );
has 'query_start'      => ( is => 'ro', isa => 'Str', required => 1 );
has 'query_end'        => ( is => 'ro', isa => 'Str', required => 1 );

sub match_start { $_[0]->hit_start }
sub match_end   { $_[0]->hit_end }

__PACKAGE__->meta->make_immutable();
1;
