use Test2::V0 qw( ok done_testing );
use Types::Standard -types;
use Type::Utils::Generics qw( generics T );

package Column {
  use Mouse;
  use Types::Standard -types;
  has name => (
    is       => 'ro',
    isa      => Str,
    required => 1,
  );
}

package Columns {
  use Mouse;
  use Types::Standard -types;
  has contents => (
    is       => 'ro',
    isa      => ArrayRef[ InstanceOf['Column'] ],
    required => 1,
  );
}

my $ColumnsType = generics Columns => (
  class_name => 'Columns',
  attributes => +{ contents => T(0) },
);
my $ParameterizeType = $ColumnsType->([ ArrayRef[InstanceOf['Column']] ]);

my $columns = Columns->new(contents => [ Column->new(name => '日野森雫') ]);
ok $ParameterizeType->check($columns);

done_testing;
