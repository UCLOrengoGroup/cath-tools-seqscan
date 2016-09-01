package Cath::Search::Hit;

=head1 NAME

Cath::Search::Hit - abstracts Bio::Search::Hit::HitI

=head1 SYNOPSIS

  $hit->name;
  $hit->significance;
  $hit->rank;
  $hit->list_all_hsps;

=cut

use Cath::Moose;
use Cath::Types qw/ ArrayOfSearchHSPs CathID DomainID Num Str /;
use Cath::Search::HSP;
use Cath::SequenceHeader;
use Cath::Util;
use Cath::SSGID;
use Try::Tiny;
use MooseX::Storage;
use namespace::autoclean;

with Storage();
with 'Cath::Role::Logable';
with 'Cath::Role::HasMetaData';

sub BUILD {
  my $self = shift;
  $self->parse_name;
}

has 'match_name'   => ( is => 'ro', isa => 'Str', required => 1 );
has 'match_length' => ( is => 'ro', isa => 'Num', required => 1 );
has 'significance' => ( is => 'ro', isa => 'Num', required => 1 );
has 'rank'         => ( is => 'ro', isa => 'Num', required => 1 );

has 'match_id'            => (is => 'rw', isa => Str,      predicate => 'has_match_id');
has 'match_cath_id'       => (is => 'rw', isa => CathID,   coerce => 1, predicate => 'has_match_cath_id');
has 'match_domain_id'     => (is => 'rw', isa => DomainID, coerce => 1, predicate => 'has_match_domain_id');
has 'match_funfam_number' => (is => 'rw', isa => Num,      predicate => 'has_match_funfam_id');
has 'match_description'   => (is => 'rw', isa => Str,      default => '');
has 'match_type'          => (is => 'rw', isa => Str,      default => 'unknown');

sub evalue { $_[0]->significance }

has 'hsps' => (
  traits     => ['Array'],
  is         => 'ro',
  isa        => ArrayOfSearchHSPs,
  coerce     => 1,
  default    => sub { [] },
  handles => {
    get_hsp => 'get',
    count_hsps => 'count',
    list_all_hsps => 'elements',
  }
);

sub first_query_res {
  my $self = shift;
  my @sorted_hsps = sort { $a->query_start cmp $b->query_end } $self->list_all_hsps;
  if ( scalar @sorted_hsps >= 1 ) {
    return $sorted_hsps[0]->query_start;
  }
  else {
    $self->log_warn( "Warning: failed to get first_query_res() for hit (no HSPs)" );
    return;
  }
}

sub parse_name {
  my $self = shift;

  my $match_name = $self->match_name;

  # try and parse the headers we might find...
  # S35:    'cath|4_0_0|3b85A00/116'
  # FUNFAM: '3.30.70.330/FF/27073'
  my $superfamily_id;
  my $funfam_number;
  my $domain_id;
  my $match_id;
  my $description;
  my $id_type;

  if ( Cath::Util::is_valid_funfam_id( $match_name ) ) {
    try {
      my $funfam_id = Cath::SSGID->new( id => $match_name );
      $superfamily_id    = $funfam_id->superfamily_id . "";
      $funfam_number     = $funfam_id->ssg_number + 0;
      $match_id          = $funfam_id->to_string( padded => 0 );
      $id_type           = 'funfam';
      $description = "CATH Functional Family $match_id";
    }
    catch {
      $self->log_warn( "failed to get information from FunFam ID: $_" );
    };
  }
  else {
    try {
      # get rid of any iteration labels from the end of the model name
      $match_name =~ s/-i\d$//;
      # note we can only use a hard coded CATH version because we are
      # turning this straight back into a standard ID (not object)
      my $header = Cath::SequenceHeader->new_from_string( $match_name, cath_version => 'latest' );
      $domain_id  = "" . $header->id;
      $match_id   = $domain_id;
      $id_type = 'domain';
      $description = "CATH Domain $domain_id";
    }
    catch {
      $self->log_trace( "could not parse '$match_name' as SequenceHeader: $_" );
    };
  }
  
  $self->match_id( "$match_id" )                   if $match_id;
  $self->match_cath_id( "$superfamily_id" )        if $superfamily_id;
  $self->match_domain_id( "$domain_id" )           if $domain_id;
  $self->match_funfam_number( 0 + $funfam_number ) if $funfam_number;
  $self->match_description( $description )         if $description;
  $self->match_type( $id_type )                    if $id_type;
}

__PACKAGE__->meta->make_immutable();
1;
