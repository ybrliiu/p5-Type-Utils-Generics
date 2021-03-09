use Test2::V0;
use Types::Standard -types;
use lib 't/lib';
use Queue qw( QueueType );

subtest 'Queue[Str]' => sub {
  my $QueueStrType = QueueType[Str];
  ok $QueueStrType->check( Queue->new(data => ['A']) );
  ok !$QueueStrType->check( Queue->new(data => [ +{} ]) );
  ok !$QueueStrType->check( Queue->new(data => [ (undef) x 3 ]) );
};

{
  package User;
  use Moo;
  use Types::Standard -types;
  has name => (
    is       => 'ro',
    isa      => Str,
    required => 1,
  );
}

subtest 'Queue[User]' => sub {
  my $QueueUserType = QueueType[ InstanceOf['User'] ];
  ok $QueueUserType->check( Queue->new(data => [ User->new(name => '日野森雫') ]) );
  ok $QueueUserType->check( Queue->new(data => []) );
  ok !$QueueUserType->check( Queue->new(data => [1, 2]) );
};

done_testing;
