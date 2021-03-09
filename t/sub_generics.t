use Test2::V0;
use Types::Standard -types;
use lib 't/lib';
use Find qw( FindType find );
use Sub::WrapInType qw( wrap_sub );

subtest 'Find[Int]' => sub {
  my $FindInt = FindType[Int];
  # is $FindInt, 'FindType[Int]';
  is $FindInt, 'FindType[ [ArrayRef[Int], Int] => Int ]';
  ok $FindInt->check(wrap_sub([ ArrayRef[Int], Int ] => Int, \&find));
  ok !$FindInt->check(wrap_sub([ Int, Int ] => Int, \&find));
  ok !$FindInt->check(wrap_sub([ ArrayRef[Int], Undef ] => Int, \&find));
};

done_testing;
