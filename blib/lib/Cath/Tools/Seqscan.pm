package Cath::Tools::Seqscan;

use Moo;
use JSON::Any;
use Path::Class;
use REST::Client;
use URI;

with 'MooX::Options';

has 'host' => (
  doc => 'Host to use for API requests'
  is => 'ro',
  default => 'http://beta.cathdb.info/',
);

has 'in' => (
  doc => 'Query sequence to scan (FASTA file)',
  is => 'ro',
  required => 1,
);

sub run {
  my $self = shift;

  my $query = file( $self->in )->slurp;

  my $client = REST::Client->new();

  $client->setHost( $self->host );

  $client->POST( '/search/by_funfhmmer',
    { fasta => $query },
    { 'Content-accept' => 'application/json' }
  );

  warn $client->responseContent();

}
