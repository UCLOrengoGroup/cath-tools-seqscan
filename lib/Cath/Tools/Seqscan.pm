package Cath::Tools::Seqscan;

=head1 NAME

Cath::Tools::Seqscan - scan sequence against funfams in CATH

=head1 SYNOPSIS

  # take params from the command line
  $app = Cath::Tools::Seqscan->new_with_options()

  # create from code
  $app = Cath::Tools::Seqscan->new(
    in  => '/path/to/fasta.fa',
    out => '/path/to/output/dir/',
  );

  $app->run;

=cut

use Moo;
use MooX::Options;
use JSON::MaybeXS;
use Path::Tiny;
use HTTP::Tiny;
use Try::Tiny;
use Log::Dispatch;
use Data::Dumper;
use URI;
use IO::String;
use Carp qw/ confess /;

use Cath::Tools::Types qw/ is_CathDomainID /;

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

my $QUEUE_NAME_PREFIX = 'hmmscan_';

has 'client' => ( is => 'ro', lazy => 1, builder => '_build_client' );
has 'json'   => ( is => 'ro', default => sub { JSON::MaybeXS->new() } );

sub _build_client {
  my $self = shift;
  my $http = HTTP::Tiny->new();
}

option 'host' => (
  doc => 'Host to use for API requests',
  format => 's',
  is => 'ro',
  default => 'http://www.cathdb.info',
);

option 'in' => (
  doc => 'Query sequence to submit (FASTA file)',
  format => 's',
  is => 'ro',
  required => 1,
);

option 'queue' => (
  doc => 'Specify a custom queue',
  format => 's',
  is => 'ro',
  default => 'api',
);

option 'out' => (
  doc => 'Directory to output alignments (STOCKHOLM format)',
  format => 's',
  is => 'ro',
  default => sub { path('.') }
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

  my $query = path( $self->in )->slurp;

  my $json          = $self->json;
  my $dir_out       = path( $self->out );
  my $max_aln_count = $self->max_aln;
  my $max_hit_count = $self->max_hits;

  my $host          = $self->host;

  if ( ! -d $dir_out ) {
    $log->info( "Output directory `$dir_out` does not exist - creating ...\n" );
    $dir_out->mkpath
      or die "! Error: failed to create directory: $!";
  }

  $log->info( sprintf "Using host $host\n" );

  my $queue_name = $QUEUE_NAME_PREFIX . $self->queue;
  my $body = $json->encode( { fasta => $query, queue => $queue_name } );

  $log->info( "Submitting sequence... \n" );
  my $submit_content = $self->POST( "$host/search/by_funfhmmer", $body );
  my $task_id = $json->decode( $submit_content )->{task_id};
  $log->info( "Sequence submitted... got task id: $task_id\n");

  my $is_finished = 0;
  while( !$is_finished ) {

    my $check_content = $self->GET( "$host/search/by_funfhmmer/check/$task_id" );

    my $status = try { $json->decode( $check_content )->{message} }
    catch {
        die "! Error: failed to decode content: " . substr( $check_content, 0, 100 ) . '...';
    };

    die "! Error: expected 'message' in response"
      unless defined $status;

    $log->info( "status: $status\n" );

    if ( $status eq 'error' || $status eq 'done' ) {
      $is_finished = 1;
    }

    sleep(1);
  }

  $log->info( "Retrieving scan results for task id: $task_id\n" );

  my $results_content = $self->GET( "$host/search/by_funfhmmer/results/$task_id?max_hits=$max_hit_count" );
  my $scan = $json->decode( $results_content )->{funfam_scan};

  # prints out the entire data structure
  #warn Dumper( $scan );
  my $result    = $scan->{results}->[0];

  for my $hit ( @{ $result->{hits} } ) {
    $log->info( sprintf "HIT  %-30s %.1e %s\n", $hit->{match_id}, $hit->{significance}, $hit->{match_description} );
  }

  my @hits = @{ $result->{hits} };

  for (my $hit_idx=0; $hit_idx < $max_aln_count && $hit_idx < scalar @hits; $hit_idx++) {
    my $hit_id = $hits[ $hit_idx ]->{match_id};

    $log->info( sprintf "Retrieving alignment [%d] %s ...\n", $hit_idx + 1, $hit_id );

    my $align_body = $json->encode( { task_id => $task_id, hit_id => $hit_id } );
    my $align_content = $self->POST( "$host/search/by_sequence/align_hit", $align_body );

    (my $file_name = $hit_id ) =~ s{[^0-9a-zA-Z\-_\.]}{-}g;
    my $file_out = $dir_out->path( $file_name . ".sto" );

    # write the alignment out, fixing the domain boundaries as we go...
    $log->info( "Writing alignment to file $file_out ... \n" );

    my $fh_out = $file_out->openw()
      or die "! Error: failed to output alignment to file '$file_out': $!";

    print $fh_out $align_content;
    close( $fh_out );
  }

  return 1;
}

sub POST {
  my ($self, $url, $body, $headers) = @_;

  $headers ||= {};
  $headers = { %DEFAULT_HEADERS, %$headers };

  my $client = $self->client;

  $log->info( sprintf "%-6s %-70s", "POST", $url );
  my $response = $client->post( $url, { content => $body, headers => $headers } );
  $log->info( sprintf " %d\n", $response->{status} );

  if ( ! $response->{success} ) {
    $log->info( "ERROR: response: " . $response->{content} . "\n" );
    die "! Error: expected response code 20*";
  }

  return $response->{content};
}

sub GET {
  my ($self, $url, $headers) = @_;

  $headers ||= {};
  $headers = { %DEFAULT_HEADERS, %$headers };

  my $client = $self->client;

  $log->info( sprintf "%-6s %-70s", "GET", $url );
  my $response = $client->get( $url, { headers => $headers } );
  $log->info( sprintf " %d\n", $response->{status} );

  die "! Error: expected response code 20*"
    unless $response->{success};

  return $response->{content};
}

1;
