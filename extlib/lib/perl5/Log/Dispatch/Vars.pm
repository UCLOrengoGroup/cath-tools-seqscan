package Log::Dispatch::Vars;

use strict;
use warnings;

our $VERSION = '2.57';

use Exporter qw( import );

our @EXPORT_OK = qw(
    %CanonicalLevelNames
    %LevelNamesToNumbers
    @OrderedLevels
);

our %CanonicalLevelNames = (
    (
        map { $_ => $_ }
            qw(
            debug
            info
            notice
            warning
            error
            critical
            alert
            emergency
            )
    ),
    warn  => 'warning',
    err   => 'error',
    crit  => 'critical',
    emerg => 'emergency',
);

our @OrderedLevels = qw(
    debug
    info
    notice
    warning
    error
    critical
    alert
    emergency
);

our %LevelNamesToNumbers = (
    ( map { $OrderedLevels[$_] => $_ } 0 .. $#OrderedLevels ),
    warn  => 3,
    err   => 4,
    crit  => 5,
    emerg => 7
);

1;

# ABSTRACT: Variables used internally by multiple packages

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Dispatch::Vars - Variables used internally by multiple packages

=head1 VERSION

version 2.57

=head1 DESCRIPTION

There are no user-facing parts here.

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
