[![Actions Status](https://github.com/ybrliiu/p5-Type-Utils-Generics/workflows/test/badge.svg)](https://github.com/ybrliiu/p5-Type-Utils-Generics/actions) [![Coverage Status](https://img.shields.io/coveralls/ybrliiu/p5-Type-Utils-Generics/master.svg?style=flat)](https://coveralls.io/r/ybrliiu/p5-Type-Utils-Generics?branch=master) [![MetaCPAN Release](https://badge.fury.io/pl/Type-Utils-Generics.svg)](https://metacpan.org/release/Type-Utils-Generics)
# NAME

Type::Utils::Generics - Create generics type easily

# SYNOPSIS

    use Type::Utils::Generics qw( class_generics T );
    
    package Queue {
      use Moo;
      use Types::Standard -types;
      has data => (
        is       => 'ro',
        isa      => ArrayRef,
        required => 1,
      );
    }
    
    class_generics QueueType => (
      class_name => 'Queue',
      attributes => +{ data => ArrayRef[ T(0) ] },
    );

    subtest 'Queue[Str]' => sub {
      my $QueueStrType = QueueType([Str]);
      ok $QueueStrType->check( Queue->new(data => ['A']) );
      ok !$QueueStrType->check( Queue->new(data => [ +{} ]) );
      ok !$QueueStrType->check( Queue->new(data => [ (undef) x 3 ]) );
    };

    # TODO: implement 

    my $Find = sub_generics Find => (
      params  => [ ArrayRef[ T(0) ], T(0) ],
      returns => T(0),
    );
    # or...
    my $Find = sub_generics Find => [ ArrayRef[ T(0) ], T(0) ] => T(0);

    my $FindInt = $Find->(Int); # TypedCodeRef[ [ ArrayRef[Int], Int ] => Int ]

# DESCRIPTION

Type::Utils::Generics is ...

# LICENSE

Copyright (C) ybrliiu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

ybrliiu <raian@reeshome.org>
