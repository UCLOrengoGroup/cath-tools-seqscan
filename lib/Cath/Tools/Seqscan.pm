package Cath::Tools::Seqscan;

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

has 'client' => ( is => 'ro', default => sub { REST::Client->new() } );
has 'json'   => ( is => 'ro', default => sub { JSON::Any->new() } );

option 'host' => (
  doc => 'Host to use for API requests',
  format => 's',
  is => 'ro',
  default => 'http://beta.cathdb.info/',
);

option 'in' => (
  doc => 'Query sequence to scan (FASTA file)',
  format => 's',
  is => 'ro',
  required => 1,
);

sub run {
  my $self = shift;

  my $query = file( $self->in )->slurp;

  my $client = $self->client;
  my $json   = $self->json;

  $client->setHost( $self->host );

  my $body = $json->to_json( { fasta => $query } );

  my $submit_content = $self->POST( "/search/by_funfhmmer", $body );

  my $task_id = $json->from_json( $submit_content )->{task_id};

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

  my $results_content = $self->GET( "/search/by_funfhmmer/results/$task_id" );


}

sub POST {
  my ($self, $url, $body, $headers) = @_;
  $headers ||= { 'Content-type' => 'application/json', 'Content-Accept' => 'application/json' };
  my $client = $self->client;
  $log->info( sprintf "%-6s %-70s", "POST", $url );
  $self->client->POST( $url, $body, $headers );
  $log->info( sprintf " %d\n", $client->responseCode );
  die "! Error: expected response code 20*"
    unless $client->responseCode =~ /^20/;
  return $client->responseContent;
}

sub GET {
  my ($self, $url, $headers) = @_;
  $headers ||= { 'Content-type' => 'application/json', 'Content-Accept' => 'application/json' };
  my $client = $self->client;
  $log->info( sprintf "%-6s %-70s", "GET", $url );
  $client->GET( $url, $headers );
  $log->info( sprintf " %d\n", $client->responseCode );
  die "! Error: expected response code 20*"
    unless $client->responseCode =~ /^20/;
  return $client->responseContent;
}

1;
