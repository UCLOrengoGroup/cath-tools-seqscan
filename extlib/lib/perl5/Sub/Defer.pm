package Sub::Defer;

use Moo::_strictures;
use Exporter qw(import);
use Moo::_Utils qw(_getglob _install_coderef);
use Scalar::Util qw(weaken);
use Carp qw(croak);

our $VERSION = '2.002004';
$VERSION = eval $VERSION;

our @EXPORT = qw(defer_sub undefer_sub undefer_all);
our @EXPORT_OK = qw(undefer_package defer_info);

our %DEFERRED;

sub undefer_sub {
  my ($deferred) = @_;
  my ($target, $maker, $undeferred_ref) = @{
    $DEFERRED{$deferred}||return $deferred
  };
  return ${$undeferred_ref}
    if ${$undeferred_ref};
  ${$undeferred_ref} = my $made = $maker->();

  # make sure the method slot has not changed since deferral time
  if (defined($target) && $deferred eq *{_getglob($target)}{CODE}||'') {
    no warnings 'redefine';

    # I believe $maker already evals with the right package/name, so that
    # _install_coderef calls are not necessary --ribasushi
    *{_getglob($target)} = $made;
  }
  $DEFERRED{$made} = $DEFERRED{$deferred};
  weaken $DEFERRED{$made}
    unless $target;

  return $made;
}

sub undefer_all {
  undefer_sub($_) for keys %DEFERRED;
  return;
}

sub undefer_package {
  my $package = shift;
  undefer_sub($_)
    for grep {
      my $name = $DEFERRED{$_} && $DEFERRED{$_}[0];
      $name && $name =~ /^${package}::[^:]+$/
    } keys %DEFERRED;
  return;
}

sub defer_info {
  my ($deferred) = @_;
  my $info = $DEFERRED{$deferred||''} or return undef;
  [ @$info ];
}

sub defer_sub {
  my ($target, $maker, $options) = @_;
  my $package;
  my $subname;
  ($package, $subname) = $target =~ /^(.*)::([^:]+)$/
    or croak "$target is not a fully qualified sub name!"
    if $target;
  $package ||= $options && $options->{package} || caller;
  my @attributes = @{$options && $options->{attributes} || []};
  my $deferred;
  my $undeferred;
  my $deferred_info = [ $target, $maker, \$undeferred ];
  if (@attributes || $target && !Moo::_Utils::_CAN_SUBNAME) {
    my $code
      =  q[#line ].(__LINE__+2).q[ "].__FILE__.qq["\n]
      . qq[package $package;\n]
      . ($target ? "sub $subname" : '+sub') . join(' ', map ":$_", @attributes)
      . q[ {
        package Sub::Defer;
        # uncoverable subroutine
        # uncoverable statement
        $undeferred ||= undefer_sub($deferred_info->[3]);
        goto &$undeferred; # uncoverable statement
        $undeferred; # fake lvalue return
      }]."\n"
      . ($target ? "\\&$subname" : '');
    my $e;
    $deferred = do {
      no warnings qw(redefine closure);
      local $@;
      eval $code or $e = $@; # uncoverable branch true
    };
    die $e if defined $e; # uncoverable branch true
  }
  else {
    # duplicated from above
    $deferred = sub {
      $undeferred ||= undefer_sub($deferred_info->[3]);
      goto &$undeferred;
    };
    _install_coderef($target, $deferred)
      if $target;
  }
  weaken($deferred_info->[3] = $deferred);
  weaken($DEFERRED{$deferred} = $deferred_info);
  return $deferred;
}

sub CLONE {
  %DEFERRED = map { defined $_ && $_->[3] ? ($_->[3] => $_) : () } values %DEFERRED;
  foreach my $info (values %DEFERRED) {
    weaken($info)
      unless $info->[0] && ${$info->[2]};
  }
}

1;
__END__

=head1 NAME

Sub::Defer - defer generation of subroutines until they are first called

=head1 SYNOPSIS

 use Sub::Defer;

 my $deferred = defer_sub 'Logger::time_since_first_log' => sub {
    my $t = time;
    sub { time - $t };
 };

  Logger->time_since_first_log; # returns 0 and replaces itself
  Logger->time_since_first_log; # returns time - $t

=head1 DESCRIPTION

These subroutines provide the user with a convenient way to defer creation of
subroutines and methods until they are first called.

=head1 SUBROUTINES

=head2 defer_sub

 my $coderef = defer_sub $name => sub { ... };

This subroutine returns a coderef that encapsulates the provided sub - when
it is first called, the provided sub is called and is -itself- expected to
return a subroutine which will be goto'ed to on subsequent calls.

If a name is provided, this also installs the sub as that name - and when
the subroutine is undeferred will re-install the final version for speed.

Exported by default.

=head2 undefer_sub

 my $coderef = undefer_sub \&Foo::name;

If the passed coderef has been L<deferred|/defer_sub> this will "undefer" it.
If the passed coderef has not been deferred, this will just return it.

If this is confusing, take a look at the example in the L</SYNOPSIS>.

Exported by default.

=head2 undefer_all

 undefer_all();

This will undefer all deferred subs in one go.  This can be very useful in a
forking environment where child processes would each have to undefer the same
subs.  By calling this just before you start forking children you can undefer
all currently deferred subs in the parent so that the children do not have to
do it.  Note this may bake the behavior of some subs that were intended to
calculate their behavior later, so it shouldn't be used midway through a
module load or class definition.

Exported by default.

=head2 undefer_package

  undefer_package($package);

This undefers all deferred subs in a package.

Not exported by default.

=head1 SUPPORT

See L<Moo> for support and contact information.

=head1 AUTHORS

See L<Moo> for authors.

=head1 COPYRIGHT AND LICENSE

See L<Moo> for the copyright and license.

=cut
