package Find;
use strict;
use warnings;
use utf8;

use Exporter qw( import );
our @EXPORT_OK = qw( find FindType );

use List::Util qw( any );
use Types::Standard -types;
use Type::Utils::Generics qw( sub_generics T );

sub_generics FindType => (
  params => [ ArrayRef[T(0)], T(0) ],
  isa    => T(0),
);

sub find {
  my ($ary, $val) = @_;
  any { $_ == $val } @$ary;
}

1;
