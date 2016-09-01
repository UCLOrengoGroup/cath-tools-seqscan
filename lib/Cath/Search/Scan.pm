package Cath::Search::Scan;

=head1 NAME

Cath::Search::Scan - abstracts Bio::SearchIO

=head1 SYNOPSIS

  $io = Bio::SearchIO->new( ... );

  $scan = Cath::Search::Scan->new( $io );

  $scan->list_all_results; # ( Cath::Search::Result, ... )

  $scan->freeze;

=cut

use Moo;
use Cath::Search::Result;
use Cath::Search::Hit;
use Cath::Search::HSP;
use List::MoreUtils qw/ uniq /;
use namespace::autoclean;

has results => (
  traits       => ['Array'],
  is           => 'ro',
  coerce       => 1,
  lazy         => 1,
  default      => sub { [] },
  handles      => {
    'get_result'       => 'get',
    'count_results'    => 'count',
    'list_all_results' => 'elements',
    'find_result'      => 'first',
    'add_result'       => 'push',
  }
);

sub list_all_match_ids {
  my $self = shift;
  return uniq map { $_->match_id } map { $_->list_all_hits } $self->list_all_results;
}

sub new_from_searchio {
  my $class = shift if $_[0] eq __PACKAGE__;
	my $self  = shift if ref $_[0] eq __PACKAGE__;
	my $in = shift;

	#warn "Parsing results...";
	my @results;
	while ( my $result = $in->next_result ) {
		my @hits;
		while ( my $hit = $result->next_hit ) {
			my @hsps;
			while ( my $hsp = $hit->next_hsp ) {

				push @hsps, Cath::Search::HSP->new(
					evalue           => $hsp->evalue,
          frac_identical   => $hsp->frac_identical,
          frac_conserved   => $hsp->frac_conserved,
					query_string     => $hsp->query_string,
					hit_string       => $hsp->hit_string,
					homology_string  => $hsp->homology_string,
          algorithm        => $hsp->algorithm,
					length           => $hsp->length,
					rank             => $hsp->rank,
					score            => $hsp->score,

					query_start      => $hsp->start('query'),
					query_end        => $hsp->end('query'),
					hit_start        => $hsp->start('hit'),
					hit_end          => $hsp->end('hit'),

					# NOTE: the following fields are documented by Bio::Search::HSP::HSPI
					# but seemingly not implemented by the HMM parser
					#
					#frac_identical   => $hsp->frac_identical,
					#frac_conserved   => $hsp->frac_conserved,
					#num_identical    => $hsp->num_identical,
					#num_conserved    => $hsp->num_conserved,
					#percent_identity => $hsp->percent_identity,
					#bits             => $hsp->bits,
				);
			}
			push @hits, Cath::Search::Hit->new(
				match_name   => $hit->name,
        match_length => $hit->length,
				significance => $hit->significance,
				rank         => $hit->rank,
				hsps         => \@hsps,
			);
		}

		next unless scalar @hits > 0;

		push @results, Cath::Search::Result->new(
			query_name        => $result->query_name,
			query_length      => $result->query_length,

      # opportunity to store local annotations...
      # query_cath_id     => '',

			hits              => \@hits,
			#query_accession   => $result->query_accession,
			#query_description => $result->query_description,
			#database_name     => $result->database_name,
		);
	}

	# sort results by lowest $_->{hits}->[ {significance} ]
	@results = sort _results_by_most_significant_hit @results;

	return __PACKAGE__->new( results => \@results );
}

sub _results_by_most_significant_hit {
	my $best_hit_score_a = List::Util::min map { 0+$_->{significance} } @{ $a->{hits} };
	my $best_hit_score_b = List::Util::min map { 0+$_->{significance} } @{ $b->{hits} };
	return (0+$best_hit_score_a) <=> (0+$best_hit_score_b);
}

__PACKAGE__->meta->make_immutable();
1;
