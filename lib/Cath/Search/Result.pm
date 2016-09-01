package Cath::Search::Result;


=head1 NAME

Cath::Search::Result - abstracts Bio::Search::Result::ResultI

=head1 SYNOPSIS

  $result->query_name;
  $result->query_length;
  $result->list_all_hits;
  $result->count_hits;

=cut

use Cath::Moose;
use Cath::Types qw/ ArrayOfSearchHits Str CathID DomainID SSGID /;
use Cath::Util;
use Cath::SSGID;
use Cath::SequenceHeader;
use Cath::Search::HSP;
use MooseX::Storage;
use namespace::autoclean;

with Storage();
with 'Cath::Role::HasMetaData';

has 'query_name'         => ( is => 'ro', isa => 'Str', required => 1 );
has 'query_length'       => ( is => 'ro', isa => 'Int', required => 1 );

has 'query_id' => (is => 'ro', isa => 'Str', lazy => 1, builder => '_build_query_id');
sub _build_query_id { $_[0]->query_name }

has 'query_cath_id'     => (is => 'rw', isa => CathID,   coerce => 1, predicate => 'has_query_cath_id');
has 'query_domain_id'   => (is => 'rw', isa => DomainID, coerce => 1, predicate => 'has_query_domain_id');
has 'query_funfam_id'   => (is => 'rw', isa => SSGID,    coerce => 1, predicate => 'has_query_funfam_id');
has 'query_description' => (is => 'rw', isa => Str,      default => '');

has 'hits' => (
  traits     => ['Array'],
  is         => 'ro',
  isa        => ArrayOfSearchHits,
  coerce     => 1,
  default    => sub { [] },
  handles => {
    get_hit            => 'get',
    add_hits           => 'push',
    count_hits         => 'count',
    list_all_hits      => 'elements',
    sort_hits_in_place => 'sort_in_place',
    find_hit           => 'first',
    splice_hits        => 'splice',
  }
);

# allow coercions
around 'add_hits' => sub {
	my $orig = shift;
	my $self = shift;
	my @hits = map { to_SearchHit( $_ ) } @_;
	return $self->$orig( @hits );
};

sub add_hit {
	my $self = shift;
	my $params = scalar @_ == 1 ? $_[0] : { @_ };   # allow HASH or HASHREF
	$self->add_hits( $params );
}

sub order_hits {
	my $self = shift;
	$self->sort_hits_in_place( sub { $_[0]->first_query_res <=> $_[1]->first_query_res } );
}

sub to_json {
	my $self = shift;
	return $self->freeze;
}

sub to_tsv {
	my ($self, %params) = validated_hash(\@_,
    max_hits => { isa => 'Int', optional => 1 },
  );

  my $max_hits;
  if ( $params{max_hits} ) {
    $max_hits = $params{max_hits};
  }

	my $join_char         = "\t";
	my $missing_info_char = "-";
	my $text = '';

	#$text .= join( $join_char, #QUERY", "MATCH", "TYPE", "QUERY_REGION" "MATCH_REGION", "LENGTH", "HIT_EVALUE" ) . "\n";

  my $current_hit = 0;
	HIT: for my $hit ( $self->list_all_hits ) {
		my $hit_data = $hit->data;
		for my $hsp ( $hit->list_all_hsps ) {
			my $hsp_data = $hsp->data;
			$text .= join( $join_char,
				$self->query_id,
				$hit->match_id,
				$hit->match_type              || $missing_info_char,
        $hsp->query_start . '-' . $hsp->query_end,
				$hsp->match_start   . '-' . $hsp->match_end,
				$hsp->length                  || $missing_info_char,
				$hsp->evalue                  || $missing_info_char,
			) . "\n";
		}
    $current_hit++;
    if ( $max_hits && $current_hit > $max_hits ) {
      last HIT;
    }
	}

	return $text;
}


__PACKAGE__->meta->make_immutable();
1;
