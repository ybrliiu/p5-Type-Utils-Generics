package Type::Utils::Generics;
use 5.010001;
use strict;
use warnings;
use utf8;
our $VERSION = '0.01';

use Exporter qw( import );
our @EXPORT_OK = qw( class_generics sub_generics T TypeParameter );
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

use Type::Params qw( signature );
use Types::Standard -types, qw( slurpy );
use Type::Utils::Generics::TypeParameterType qw( T TypeParameter );
use Sub::Util qw( set_subname set_prototype );
use aliased 'Type::Utils::Generics::Class';
use aliased 'Type::Utils::Generics::Subroutine';

my $TypeContraint = HasMethods[qw( check get_message )];

sub class_generics {
  my $name = @_ % 2 == 1 ? shift : undef;
  state $check = signature(
    named_to_list => 1,
    named => [
      class_name => ClassName,
      attributes => HashRef[$TypeContraint],
    ],
  );
  my ($class_name, $type_template_of_attribute) = $check->(@_);

  my $code = sub {
    state $c = signature(positional => [ ArrayRef[$TypeContraint], { default => sub { [] } } ]);
    my ($type_parameters) = $c->(@_);

    my $factory = Class->new(
      name                       => $name,
      class_name                 => $class_name,
      type_template_of_attribute => $type_template_of_attribute,
      type_parameters            => $type_parameters,
    );
    $factory->create();
  };

  if (defined $name) {
    my $caller = caller;
    no strict 'refs';
    *{ $caller . '::' . $name } = $code;
    set_subname($name, $code);
    set_prototype(';$', $code);
  }

  $code;
}

sub sub_generics {
  my $name = @_ % 2 == 1 ? shift : undef;
  state $check = do {
    # TODO: この型いろんなところで出現している
    my $TypeConstraint = InstanceOf['Type::Tiny'];
    my $ParamsTypes    = $TypeConstraint | ArrayRef[$TypeConstraint] | HashRef[$TypeConstraint];
    my $ReturnTypes    = $TypeConstraint | ArrayRef[$TypeConstraint];
    signature(
      message => << 'EOS',
USAGE: sub_generics(\@parameter_types, $return_types)
    or sub_generics(params => \@params_types, returns => $return_types)
EOS
      multi => [
        +{ positional => [ $ParamsTypes, $ReturnTypes ] },
        +{
          named_to_list => 1,
          named => [
            params => $ParamsTypes,
            isa    => $ReturnTypes,
          ],
        },
      ]
    );
  };
  my ($params_types, $return_types) = $check->(@_);

  my $code = sub {
    state $c = signature(positional => [ ArrayRef[$TypeContraint] ]);
    my ($type_parameters) = $c->(@_);

    my $factory = Subroutine->new(
      name                        => $name,
      type_template_of_parameters => $params_types,
      type_template_of_returns    => $return_types,
      type_parameters             => $type_parameters,
    );
    $factory->create();
  };

  if (defined $name) {
    my $caller = caller;
    no strict 'refs';
    *{ $caller . '::' . $name } = $code;
    set_subname($name, $code);
    set_prototype(';$', $code);
  }

  $code;
}

1;
__END__

=encoding utf-8

=head1 NAME

Type::Utils::Generics - Create generics type easily

=head1 SYNOPSIS

    use Type::Utils::Generics qw( class_generics sub_generics T );
    
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

    my $Find = sub_generics Find => (
      params => [ ArrayRef[ T(0) ], T(0) ],
      isa    => T(0),
    );
    # or...
    my $Find = sub_generics Find => [ ArrayRef[ T(0) ], T(0) ] => T(0);

    my $FindInt = $Find->(Int); # TypedCodeRef[ [ ArrayRef[Int], Int ] => Int ]

=head1 DESCRIPTION

Type::Utils::Generics is ...

=head1 LICENSE

Copyright (C) ybrliiu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ybrliiu E<lt>raian@reeshome.orgE<gt>

=cut

