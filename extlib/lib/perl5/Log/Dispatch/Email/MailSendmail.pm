package Log::Dispatch::Email::MailSendmail;

use strict;
use warnings;

our $VERSION = '2.57';

use Log::Dispatch::Email;

use base qw( Log::Dispatch::Email );

use Mail::Sendmail ();

sub send_email {
    my $self = shift;
    my %p    = @_;

    my %mail = (
        To      => ( join ',', @{ $self->{to} } ),
        Subject => $self->{subject},
        Message => $p{message},

        # Mail::Sendmail insists on having this parameter.
        From => $self->{from} || 'LogDispatch@foo.bar',
    );

    local $?;
    unless ( Mail::Sendmail::sendmail(%mail) ) {
        warn "Error sending mail: $Mail::Sendmail::error";
    }
}

1;

# ABSTRACT: Subclass of Log::Dispatch::Email that uses the Mail::Sendmail module

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Dispatch::Email::MailSendmail - Subclass of Log::Dispatch::Email that uses the Mail::Sendmail module

=head1 VERSION

version 2.57

=head1 SYNOPSIS

  use Log::Dispatch;

  my $log = Log::Dispatch->new(
      outputs => [
          [
              'Email::MailSendmail',
              min_level => 'emerg',
              to        => [qw( foo@example.com bar@example.org )],
              subject   => 'Big error!'
          ]
      ],
  );

  $log->emerg("Something bad is happening");

=head1 DESCRIPTION

This is a subclass of L<Log::Dispatch::Email> that implements the
send_email method using the L<Mail::Sendmail> module.

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
