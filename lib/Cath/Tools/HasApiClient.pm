package Cath::Tools::HasApiClient;

use Moo::Role;

use JSON::MaybeXS;
use HTTP::Tiny;

with 'Cath::Tools::Logger';

# use these headers unless explictly state otherwise
my %DEFAULT_HEADERS = (
  'Content-Type' => 'application/json',
  'Content-Accept' => 'application/json',
);

has 'client' => ( is => 'ro', lazy => 1, builder => '_build_client' );
has 'json'   => ( is => 'ro', default => sub { JSON::MaybeXS->new() } );

sub _build_client {
  my $self = shift;
  my $http = HTTP::Tiny->new();
}

sub POST {
  my ($self, $url, $body, $headers) = @_;

  my $log = $self->_logger;

  $headers ||= {};
  $headers = { %DEFAULT_HEADERS, %$headers };

  my $client = $self->client;

  my $response = $client->post( $url, { content => $body, headers => $headers } );
  $log->info( sprintf "%-6s %-70s %d", "POST", $url, $response->{status} );

  if ( ! $response->{success} ) {
    $log->info( "ERROR: response: " . $response->{content} );
    die "! Error: expected response code 20*";
  }

  return $response->{content};
}

sub GET {
  my ($self, $url, $headers) = @_;

  my $log = $self->_logger;

  $headers ||= {};
  $headers = { %DEFAULT_HEADERS, %$headers };

  my $client = $self->client;

  my $response = $client->get( $url, { headers => $headers } );
  $log->info( sprintf "%-6s %-70s %d", "GET", $url, $response->{status} );

  die "! Error: expected response code 20*"
    unless $response->{success};

  return $response->{content};
}


1;
