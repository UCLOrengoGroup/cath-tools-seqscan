package Cath::Tools::Types;

use Type::Library
  -base,
  -declare => qw/ Segment ArrayOfSegments IdLookup CathDomainID /;

use warnings;
use Type::Utils -all;
use Types::Standard -types;
use List::Util qw/ all /;
use Carp qw/ croak /;
use Cath::Tools::Segment;

declare CathDomainID,
  where { ! ref $_ && $_ =~ /^[0-9][a-z0-9]{3}[a-zA-Z][0-9]{2}$/ },
    message { "$_ doesn't look like a CATH domain id" };


class_type Segment, { class => "Cath::Tools::Segment" };

coerce Segment,
  from Str,
    via {
      /(\-?[0-9]+[A-Z]?)-(-?[0-9]+[A-Z]?)/
        or croak "Error: string '$_' does not look like a valid residue range";
      return Cath::Tools::Segment->new( start => $1, stop => $2 );
    };

declare IdLookup,
  where { ref $_ eq 'HASH' && all { ! ref $_ } values %$_ };

coerce IdLookup,
  from ArrayRef,
    via {
      return { map { ($_ => 1) } @$_ };
    };

declare ArrayOfSegments,
   where { ref $_ eq 'ARRAY' && all { is_Segment($_) } @$_ },
   message { "$_ doesn't look like an ArrayRef of Cath::Tools::Segment to me" };

coerce ArrayOfSegments,
  from Str,
    via {
      my @segs = map { to_Segment( $_ ) } split( /,/, $_ );
      return \@segs;
    };
