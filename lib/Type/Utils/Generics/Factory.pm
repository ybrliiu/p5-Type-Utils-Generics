package Type::Utils::Generics::Factory;
use 5.010001;
use Moo;
use utf8;
use namespace::autoclean;

use aliased 'Type::Utils::Generics::TypeParameterType';
use List::Util qw( all any );
use Scalar::Util qw( blessed );
use Carp qw( confess );
use Carp::Assert qw( assert DEBUG );
use Types::Standard -types;
use Type::Utils qw( union intersection );

has name => (
  is       => 'ro',
  isa      => Maybe[Str],
  required => 1,
);

has class_name => (
  is       => 'ro',
  isa      => ClassName,
  required => 1,
);

has type_template_of_attribute => (
  is       => 'ro',
  isa      => HashRef[ InstanceOf['Type::Tiny'] ],
  required => 1,
);

has type_parameters => (
  is       => 'ro',
  isa      => ArrayRef[ InstanceOf['Type::Tiny'] ],
  required => 1,
);

sub BUILD {
  my $self = shift;
  if (DEBUG) {
    assert($self->type_parameters->@* > 0, 'type_parameters are passed.');
    assert(
      $self->find_type_parameter_type_from_all_template(),
      'TypeParameterType is included in template.'
    );
  }
}

sub find_type_parameter_type_from_all_template {
  my $self = shift;
  all { find_type_parameter_type($_) } values $self->type_template_of_attribute->%*;
}

sub find_type_parameter_type {
  my $type = shift;
  return 1 if $type->isa(TypeParameterType);

  if ( $type->is_parameterized ) {
    any { find_type_parameter_type($_) } $type->parameters->@*;
  }
  elsif ( $type->isa('Type::Tiny::Union') ) {
    any { find_type_parameter_type($_) } $type->type_constraints->@*;
  }
  elsif ( $type->isa('Type::Tiny::Intersection') ) {
    any { find_type_parameter_type($_) } $type->type_constraints->@*;
  }
  else {
    0;
  }
}

sub create_constraint_generator {
  my $self = shift;
  sub {
    sub {
      my $object = shift;
      all {
        my ($attr, $template) = ($_, $self->type_template_of_attribute->{$_});
        $self->inject_parameter_into_template($template)->check($object->$attr);
      } keys $self->type_template_of_attribute->%*;
    };
  };
}

sub inject_parameter_into_template {
  my ($self, $template) = @_;

  if ( $template->isa(TypeParameterType) ) {
    my $type_param = $self->type_parameters->[ $template->type_parameter_id ];

    unless (defined $type_param) {
      if ($template->optional) {
        # 本当は optional な type_param にデフォルト型を設定できるようにするか,
        # デフォルトの型制約をメタクラスから取ってきたほうがいい気がするけど,
        # チェック対象のインスタンス生成時に事実上デフォルト値でのチェックが行われるので Any にしてもいいかなと
        return Any;
      }
      else {
        confess 'Can not get type_parameter.';
      }
    }

    # e.g.) T[Int, Int]
    if ( $template->is_parameterized ) {
      assert $type_param->is_parameterizable if DEBUG;

      my @injected_type_params =
        map { $self->inject_parameter_into_template($_) }
        $template->parameters->@*;
      return $type_param->parameterize(@injected_type_params);
    }
    else {
      return $type_param;
    }

  }
  elsif ( $template->is_parameterized ) {
    my @injected_type_params =
      map { $self->inject_parameter_into_template($_) }
      $template->parameters->@*;
    return $template->parameterized_from->parameterize(@injected_type_params);
  }
  elsif ( $template->isa('Type::Tiny::Union') ) {
    my @injected_type_params =
      map { $self->inject_parameter_into_template($_) }
      $template->type_constraints->@*;
    return union(\@injected_type_params);
  }
  elsif ( $template->isa('Type::Tiny::Intersection') ) {
    my @injected_type_params =
      map { $self->inject_parameter_into_template($_) }
      $template->type_constraints->@*;
    return intersection(\@injected_type_params);
  }
  else {
    return $template;
  }
}

sub create {
  my $self = shift;
  Type::Tiny->new(
      parent               => InstanceOf[ $self->class_name ],
      name                 => $self->name,
      name_generator       => sub {
        $self->name . '[' . join(', ', $self->type_parameters->@*) . ']';
      },
      constraint_generator => $self->create_constraint_generator(),
    )
    ->parameterize($self->type_parameters);
}

1;
