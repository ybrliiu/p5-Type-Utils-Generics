package Queue;
use Moo;
use Exporter qw( import );

our @EXPORT_OK = qw( QueueType );

use Types::Standard -types;
use Type::Utils::Generics ':all';

class_generics QueueType => (
  class_name => 'Queue',
  attributes => +{ data => ArrayRef[ T(0) ] },
);

has data => (
  is       => 'ro',
  isa      => ArrayRef,
  required => 1,
);

1;
