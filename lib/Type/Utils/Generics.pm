package Type::Utils::Generics;
use 5.010001;
use strict;
use warnings;
use utf8;

our $VERSION = '0.01';

use Exporter qw( import );

our @EXPORT_OK = qw( generics T );
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

use aliased 'Type::Utils::Generics::Factory';
use Sub::Util qw( set_prototype );
use Type::Params qw( compile );
use Types::Standard -types, qw( slurpy );
use Type::Utils::Generics::TypeParameterType qw( T );

sub generics {
  state $c = do {
    my $NamedOptionsType = Dict[
      class_name => ClassName,
      attributes => HashRef[ InstanceOf['Type::Tiny'] ],
    ];
    compile(Str, slurpy $NamedOptionsType);
  };
  my ($name, $args) = $c->(@_);
  my ($class_name, $type_template_of_attribute) = $args->@{qw( class_name attributes )};

  my $code = sub {
    state $c = compile(ArrayRef);
    my ($type_parameters) = $c->(@_);

    my $factory = Factory->new(
      name                       => $name,
      class_name                 => $class_name,
      type_template_of_attribute => $type_template_of_attribute,
      type_parameters            => $type_parameters,
    );
    $factory->create();
  };
  set_prototype(';$', $code);
  $code;
}

1;
__END__

=encoding utf-8

=head1 NAME

Type::Utils::Generics - Create generics type easily

=head1 SYNOPSIS

    use Type::Utils::Generics qw( generics T );
    
    package Queue {
      use Moo;
      use Types::Standard -types;
      has data => (
        is       => 'ro',
        isa      => ArrayRef,
        required => 1,
      );
    }
    
    *QueueType = generics Queue => (
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

    my $QueueType = class_generics Queue => (
      class_name => 'Queue',
      attributes => +{ data => ArrayRef[ T(0) ] },
      methods    => +{
        push => [ [ T(0) ] => Undef ],
        pop  => [ [] => T(0) | Undef ],
      },
    );

=head1 DESCRIPTION

Type::Utils::Generics is ...

=head1 LICENSE

Copyright (C) ybrliiu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ybrliiu E<lt>raian@reeshome.orgE<gt>

=cut

