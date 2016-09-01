package Log::Dispatch::Base;

use strict;
use warnings;
use Scalar::Util qw( refaddr );

our $VERSION = '2.57';

sub _get_callbacks {
    shift;
    my %p = @_;

    return unless exists $p{callbacks};

    return @{ $p{callbacks} }
        if ref $p{callbacks} eq 'ARRAY';

    return $p{callbacks}
        if ref $p{callbacks} eq 'CODE';

    return;
}

sub _apply_callbacks {
    my $self = shift;
    my %p    = @_;

    my $msg = delete $p{message};
    foreach my $cb ( @{ $self->{callbacks} } ) {
        $msg = $cb->( message => $msg, %p );
    }

    return $msg;
}

sub add_callback {
    my $self  = shift;
    my $value = shift;

    Carp::carp("given value $value is not a valid callback")
        unless ref $value eq 'CODE';

    $self->{callbacks} ||= [];
    push @{ $self->{callbacks} }, $value;

    return;
}

sub remove_callback {
    my $self = shift;
    my $cb   = shift;

    Carp::carp("given value $cb is not a valid callback")
        unless ref $cb eq 'CODE';

    my $cb_id = refaddr $cb;
    $self->{callbacks}
        = [ grep { refaddr $_ ne $cb_id } @{ $self->{callbacks} } ];

    return;
}

1;

# ABSTRACT: Code shared by dispatch and output objects.

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Dispatch::Base - Code shared by dispatch and output objects.

=head1 VERSION

version 2.57

=head1 SYNOPSIS

  use Log::Dispatch::Base;

  ...

  @ISA = qw(Log::Dispatch::Base);

=head1 DESCRIPTION

Unless you are me, you probably don't need to know what this class
does.

=for Pod::Coverage add_callback

=for Pod::Coverage remove_callback

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
