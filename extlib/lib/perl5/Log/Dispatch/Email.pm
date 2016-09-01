package Log::Dispatch::Email;

use strict;
use warnings;

our $VERSION = '2.57';

use Log::Dispatch::Output;

use base qw( Log::Dispatch::Output );

use Devel::GlobalDestruction qw( in_global_destruction );
use Params::Validate qw(validate SCALAR ARRAYREF BOOLEAN);
Params::Validate::validation_options( allow_extra => 1 );

# need to untaint this value
my ($program) = $0 =~ /(.+)/;

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    my %p = validate(
        @_, {
            subject => {
                type    => SCALAR,
                default => "$program: log email"
            },
            to   => { type => SCALAR | ARRAYREF },
            from => {
                type     => SCALAR,
                optional => 1
            },
            buffered => {
                type    => BOOLEAN,
                default => 1
            },
        }
    );

    my $self = bless {}, $class;

    $self->_basic_init(%p);

    $self->{subject} = $p{subject} || "$0: log email";
    $self->{to} = ref $p{to} ? $p{to} : [ $p{to} ];
    $self->{from} = $p{from};

    # Default to buffered for obvious reasons!
    $self->{buffered} = $p{buffered};

    $self->{buffer} = [] if $self->{buffered};

    return $self;
}

sub log_message {
    my $self = shift;
    my %p    = @_;

    if ( $self->{buffered} ) {
        push @{ $self->{buffer} }, $p{message};
    }
    else {
        $self->send_email(@_);
    }
}

sub send_email {
    my $self  = shift;
    my $class = ref $self;

    die "The send_email method must be overridden in the $class subclass";
}

sub flush {
    my $self = shift;

    if ( $self->{buffered} && @{ $self->{buffer} } ) {
        my $message = join '', @{ $self->{buffer} };

        $self->send_email( message => $message );
        $self->{buffer} = [];
    }
}

sub DESTROY {
    my $self = shift;

    if (   in_global_destruction()
        && $self->{buffered}
        && @{ $self->{buffer} } ) {

        my $name  = $self->name();
        my $class = ref $self;
        my $message
            = "Log messages for the $name output (a $class object) remain unsent but the program is terminating.\n";
        $message .= "The messages are:\n";
        $message .= "  $_\n" for @{ $self->{buffer} };
    }
    else {
        $self->flush();
    }
}

1;

# ABSTRACT: Base class for objects that send log messages via email

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Dispatch::Email - Base class for objects that send log messages via email

=head1 VERSION

version 2.57

=head1 SYNOPSIS

  package Log::Dispatch::Email::MySender;

  use Log::Dispatch::Email;
  use base qw( Log::Dispatch::Email );

  sub send_email {
      my $self = shift;
      my %p    = @_;

      # Send email somehow. Message is in $p{message}
  }

=head1 DESCRIPTION

This module should be used as a base class to implement
Log::Dispatch::* objects that send their log messages via email.
Implementing a subclass simply requires the code shown in the
L<SYNOPSIS> with a real implementation of the C<send_email()> method.

=for Pod::Coverage new log_message

=head1 CONSTRUCTOR

The constructor takes the following parameters in addition to the standard
parameters documented in L<Log::Dispatch::Output>:

=over 4

=item * subject ($)

The subject of the email messages which are sent. Defaults to "$0:
log email"

=item * to ($ or \@)

Either a string or a list reference of strings containing email
addresses. Required.

=item * from ($)

A string containing an email address. This is optional and may not
work with all mail sending methods.

=item * buffered (0 or 1)

This determines whether the object sends one email per message it is
given or whether it stores them up and sends them all at once. The
default is to buffer messages.

=back

=head1 METHODS

This class provides the following methods:

=head2 $email->send_email(%p)

This is the method that must be subclassed. For now the only
parameter in the hash is 'message'.

=head2 $email->flush

If the object is buffered, then this method will call the
C<send_email()> method to send the contents of the buffer and then
clear the buffer.

=head2 $email->DESTROY

On destruction, the object will call C<flush()> to send any pending
email.

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