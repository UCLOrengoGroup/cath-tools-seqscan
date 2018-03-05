package Cath::Tools::Api::Funfam;

=head1 NAME

Cath::Tools::Api::funfam - fetch CATH FunFams from API

=head1 SYNOPSIS

  # take params from the command line
  $app = Cath::Tools::Api::Funfam->new_with_options()

  # create from code
  $app = Cath::Tools::Api::Funfam->new(
    version => '4.2',
    sfam_id => '1.10.8.10',
    out_dir => './output',
  );

  $app->run;

=cut

use Moo;
use MooX::Options;
use Try::Tiny;
use Path::Tiny;
use Data::Dumper;
use Carp qw/ confess /;

use Cath::Tools::Types qw/ is_CathSuperfamilyID to_CathVersion /;

with qw/
  Cath::Tools::HasApiClient
  Cath::Tools::Logger
/;

option 'host' => (
  doc => 'Host to use for API requests',
  format => 's',
  is => 'ro',
  default => 'http://www.cathdb.info',
);

option 'version' => (
  doc => 'Version of CATH',
  format => 's',
  is => 'ro',
  default => 'latest',
);

option 'sfam_id' => (
  doc => 'Query Superfamily ID',
  format => 's',
  is => 'ro',
  required => 1,
);

option 'out' => (
  doc => 'Directory to output alignments',
  format => 's',
  is => 'ro',
  default => sub { path('.') }
);

option 'out_format' => (
  doc => 'Output format (STO | [AFA])',
  format => 's',
  is => 'ro',
  default => 'AFA',
  short => 'format',
);

my %OUTPUT_FORMATTERS = (
  'AFA' => sub { my $text = shift; $text =~ s{^\#.*?$}{}xsmg; $text =~ s{^//.*?$}{}xsmg; $text =~ s{^\s*$}{}xmsg; return $text },
  'STO' => sub { },
);

sub run {
  my $self = shift;

  my $dir_out = path( $self->out );

  is_CathSuperfamilyID( $self->sfam_id )
    or $self->options_usage( 1, sprintf "Error: '%s' does not look like a valid CATH superfamily ID", $self->sfam_id );

  my $sfam_id = $self->sfam_id;

  my $cath_version = to_CathVersion( $self->version )
    or $self->options_usage( 2, sprintf "Error: '%s' does not look like a valid CATH version", $self->version );

  my $out_format = uc( $self->out_format );
  my $out_formatter = $OUTPUT_FORMATTERS{ $out_format }
    or $self->options_usage( 3, sprintf "Error: '%s' does not look like a valid FORMAT", $out_format );

  my $log = $self->_logger;
  my $json = $self->json;
  my $host = $self->host;

  if ( ! -d $dir_out ) {
    $log->info( "Output directory `$dir_out` does not exist - creating ..." );
    $dir_out->mkpath
      or die "! Error: failed to create directory: $!";
  }

  $log->info( sprintf "Using host $host" );

  $log->info( sprintf "Getting list of FunFams for superfamily $sfam_id..." );

  # http://www.cathdb.info/version/v4_2_0/api/rest/superfamily/1.10.8.10/funfam

  my $list_funfam_url = sprintf( "%s/version/%s/api/rest/superfamily/%s/funfam", $host, $cath_version->to_api_dir, $sfam_id );
  my $list_funfam_content = $self->GET( $list_funfam_url );
  my $list_funfam_data = try { $json->decode( $list_funfam_content )->{data} }
    catch {
      $log->error( "! Error: encountered a problem when decoding the API data: $_" );
      die;
    };

  for my $funfam_datum ( @$list_funfam_data ) {
    next unless defined $funfam_datum->{rep_id};

    my $funfam_number = $funfam_datum->{funfam_number};
    my $funfam_id = sprintf( "%s-%s-%s", $funfam_datum->{superfamily_id}, 'FF', $funfam_number );

    printf( "%-25s %-10s %-12s %s\n",
      $funfam_id,
      $funfam_datum->{rep_source_id},
      $funfam_datum->{rep_id},
      $funfam_datum->{name} || '-'
    );

    # http://www.cathdb.info/version/v4_2_0/api/rest/superfamily/1.10.8.10/funfam/15679/files/seed_alignment

    my $funfam_url = sprintf( "%s/version/%s/api/rest/superfamily/%s/funfam/%d/files/seed_alignment",
      $host, $cath_version->to_api_dir, $sfam_id, $funfam_number );

    my $funfam_content = $self->GET( $funfam_url );

    $funfam_content = $out_formatter->( $funfam_content );

    my $out_file = $dir_out->child( sprintf "%s.%s", $funfam_id, lc($out_format) );
    $log->info( sprintf "Writing sequences in %s format to %s", $out_format, $out_file );
    $out_file->spew( $funfam_content );
  }

}


1;
