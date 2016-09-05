package Cath::Tools::Seqscan;

=head1 NAME

Cath::Tools::Seqscan - scan sequence against funfams in CATH

=head1 SYNOPSIS

  $app = Cath::Tools::Seqscan->new_with_options()
  $app->run;

=cut

use Moo;
use MooX::Options;
use JSON::Any;
use Path::Class;
use REST::Client;
use Log::Dispatch;
use Data::Dumper;
use URI;

my $log = Log::Dispatch->new(
  outputs => [
    [ 'Screen', min_level => 'debug' ]
  ],
);

# use these headers unless explictly state otherwise
my %DEFAULT_HEADERS = (
  'Content-Type' => 'application/json',
  'Content-Accept' => 'application/json',
);

has 'client' => ( is => 'ro', default => sub { REST::Client->new() } );
has 'json'   => ( is => 'ro', default => sub { JSON::Any->new() } );

option 'host' => (
  doc => 'Host to use for API requests',
  format => 's',
  is => 'ro',
  default => 'http://beta.cathdb.info/',
);

option 'in' => (
  doc => 'Query sequence to submit (FASTA file)',
  format => 's',
  is => 'ro',
  required => 1,
);

option 'out' => (
  doc => 'Directory to output alignments (FASTA file)',
  format => 's',
  is => 'ro',
  default => sub { dir() }
);

option 'max_hits' => (
  doc => 'Maximum number of hits to output (default: 50)',
  format => 'i',
  is => 'ro',
  default => 50,
);

option 'max_aln' => (
  doc => 'Maximum number of alignments to output (default: 5)',
  format => 'i',
  is => 'ro',
  default => 5,
);

sub run {
  my $self = shift;

  my $query = file( $self->in )->slurp;

  my $client        = $self->client;
  my $json          = $self->json;
  my $dir_out       = dir( $self->out );
  my $max_aln_count = $self->max_aln;
  my $max_hit_count = $self->max_hits;

  if ( ! -d $dir_out ) {
    $log->info( "Output directory `$dir_out` does not exist - creating ...\n" );
    $dir_out->mkpath
      or die "! Error: failed to create directory: $!";
  }

  $log->info( sprintf "Setting host to %s\n", $self->host );
  $client->setHost( $self->host );

  my $body = $json->to_json( { fasta => $query } );

  $log->info( "Submitting sequence... \n" );
  my $submit_content = $self->POST( "/search/by_funfhmmer", $body );
  my $task_id = $json->from_json( $submit_content )->{task_id};
  $log->info( "Sequence submitted... got task id: $task_id\n");

  my $is_finished = 0;
  while( !$is_finished ) {

    my $check_content = $self->GET( "/search/by_funfhmmer/check/$task_id" );

    my $status = $json->from_json( $check_content )->{message};

    die "! Error: expected 'message' in response"
      unless defined $status;

    $log->info( "status: $status\n" );

    if ( $status eq 'error' || $status eq 'done' ) {
      $is_finished = 1;
    }

    sleep(1);
  }

  $log->info( "Retrieving scan results for task id: $task_id\n" );

  my $results_content = $self->GET( "/search/by_funfhmmer/results/$task_id?max_hits=$max_hit_count" );
  my $scan = $json->from_json( $results_content )->{funfam_scan};

  # prints out the entire data structure
  #warn Dumper( $scan );
  my $result    = $scan->{results}->[0];

  for my $hit ( @{ $result->{hits} } ) {
    $log->info( sprintf "HIT  %-30s %.1e %s\n", $hit->{match_id}, $hit->{significance}, $hit->{match_description} );
  }

  my @hits = @{ $result->{hits} };

  for (my $hit_idx=0; $hit_idx < $max_aln_count && $hit_idx < scalar @hits; $hit_idx++) {
    my $hit_id = $hits[ $hit_idx ]->{match_id};

    (my $file_name = $hit_id ) =~ s{[^0-9a-zA-Z\-_\.]}{-}g;
    my $file_out = $dir_out->file( $file_name . ".fasta" );

    $log->info( sprintf "Retrieving alignment [%d] %s ...\n", $hit_idx + 1, $hit_id );

    my $align_body = $json->to_json( { task_id => $task_id, hit_id => $hit_id } );
    my $align_content = $self->POST( "/search/by_sequence/align_hit", $align_body );

    $log->info( "Writing alignment to file $file_out\n" );
    file( $file_out )->spew( $align_content );
  }
}

sub POST {
  my ($self, $url, $body, $headers) = @_;

  $headers ||= {};
  $headers = { %DEFAULT_HEADERS, %$headers };

  my $client = $self->client;

  $log->info( sprintf "%-6s %-70s", "POST", $url );
  $self->client->POST( $url, $body, $headers );
  $log->info( sprintf " %d\n", $client->responseCode );

  if ( $client->responseCode !~ /^20/ ) {
    $log->info( "ERROR: response: " . $client->responseContent . "\n" );
    die "! Error: expected response code 20*";
  }

  return $client->responseContent;
}

sub GET {
  my ($self, $url, $headers) = @_;

  $headers ||= {};
  $headers = { %DEFAULT_HEADERS, %$headers };

  my $client = $self->client;

  $log->info( sprintf "%-6s %-70s", "GET", $url );
  $client->GET( $url, $headers );
  $log->info( sprintf " %d\n", $client->responseCode );

  die "! Error: expected response code 20*"
    unless $client->responseCode =~ /^20/;

  return $client->responseContent;
}

1;
