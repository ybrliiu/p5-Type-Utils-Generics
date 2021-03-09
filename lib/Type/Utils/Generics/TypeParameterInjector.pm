package Type::Utils::Generics::TypeParameterInjector;
use 5.010001;
use Moo;
use utf8;
use namespace::autoclean;

use aliased 'Type::Utils::Generics::TypeParameterType';
use List::Util qw( any );
use Carp qw( confess );
use Carp::Assert qw( assert DEBUG );
use Types::Standard -types;
use Type::Utils qw( union intersection );

sub find_type_parameter_type {
  my ($class, $type) = @_;

  return 1 if $type->isa(TypeParameterType);

  if ( $type->is_parameterized ) {
    any { $class->find_type_parameter_type($_) } @{ $type->parameters };
  }
  elsif ( $type->isa('Type::Tiny::Union') ) {
    any { $class->find_type_parameter_type($_) } @{ $type->type_constraints };
  }
  elsif ( $type->isa('Type::Tiny::Intersection') ) {
    any { $class->find_type_parameter_type($_) } @{ $type->type_constraints };
  }
  else {
    0;
  }
}

has type_parameters => (
  is       => 'ro',
  isa      => ArrayRef[ InstanceOf['Type::Tiny'] ],
  required => 1,
);

sub BUILD {
  my $self = shift;
  assert @{ $self->type_parameters } > 0 if DEBUG;
}

sub inject {
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

      my @injected_type_params = map { $self->inject($_) } @{ $template->parameters };
      return $type_param->parameterize(@injected_type_params);
    }
    else {
      return $type_param;
    }

  }
  elsif ( $template->is_parameterized ) {
    my @injected_type_params = map { $self->inject($_) } @{ $template->parameters };
    return $template->parameterized_from->parameterize(@injected_type_params);
  }
  elsif ( $template->isa('Type::Tiny::Union') ) {
    my @injected_type_params = map { $self->inject($_) } @{ $template->type_constraints };
    return union(\@injected_type_params);
  }
  elsif ( $template->isa('Type::Tiny::Intersection') ) {
    my @injected_type_params = map { $self->inject($_) } @{ $template->type_constraints };
    return intersection(\@injected_type_params);
  }
  else {
    return $template;
  }
}

__PACKAGE__->meta->make_immutable;

1;
