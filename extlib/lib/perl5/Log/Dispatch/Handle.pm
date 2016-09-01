package Log::Dispatch::Handle;

use strict;
use warnings;

our $VERSION = '2.57';

use Log::Dispatch::Output;

use base qw( Log::Dispatch::Output );

use Params::Validate qw(validate SCALAR ARRAYREF BOOLEAN);
Params::Validate::validation_options( allow_extra => 1 );

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    my %p = validate( @_, { handle => { can => 'print' } } );

    my $self = bless {}, $class;

    $self->_basic_init(%p);
    $self->{handle} = $p{handle};

    return $self;
}

sub log_message {
    my $self = shift;
    my %p    = @_;

    $self->{handle}->print( $p{message} )
        or die "Cannot write to handle: $!";
}

1;

# ABSTRACT: Object for logging to IO::Handle classes

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Dispatch::Handle - Object for logging to IO::Handle classes

=head1 VERSION

version 2.57

=head1 SYNOPSIS

  use Log::Dispatch;

  my $log = Log::Dispatch->new(
      outputs => [
          [
              'Handle',
              min_level => 'emerg',
              handle    => $io_socket_object,
          ],
      ]
  );

  $log->emerg('I am the Lizard King!');

=head1 DESCRIPTION

This module supplies a very simple object for logging to some sort of
handle object. Basically, anything that implements a C<print()>
method can be passed the object constructor and it should work.

=for Pod::Coverage new log_message

=head1 CONSTRUCTOR

The constructor takes the following parameters in addition to the standard
parameters documented in L<Log::Dispatch::Output>:

=over 4

=item * handle ($)

The handle object. This object must implement a C<print()> method.

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|http://rt.cpan.org/Public/Dist/Display.html?Name=Log-Dispatch>
(or L<bug-log-dispatch@rt.cpan.org|mailto:bug-log-dispatch@rt.cpan.org>).

I am also usually active on IRC as 'drolsky' on C<irc://irc.perl.org>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
