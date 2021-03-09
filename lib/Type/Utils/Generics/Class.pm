package Type::Utils::Generics::Class;
use 5.010001;
use Moo;
use utf8;
use namespace::autoclean;

use aliased 'Type::Utils::Generics::TypeParameterInjector';
use List::Util qw( all );
use Carp::Assert qw( assert DEBUG );
use Types::Standard -types;

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

has type_parameter_injector => (
  is      => 'ro',
  isa     => InstanceOf[TypeParameterInjector],
  lazy    => 1,
  default => sub {
    my $self = shift;
    TypeParameterInjector->new(type_parameters => $self->type_parameters);
  },
);

sub BUILD {
  my $self = shift;
  if ( @{ $self->type_parameters } > 0 ) {
    assert $self->find_type_parameter_type_from_all_template() if DEBUG;
  }
}

sub find_type_parameter_type_from_all_template {
  my $self = shift;

  all { $self->type_parameter_injector->find_type_parameter_type($_) }
    values %{ $self->type_template_of_attribute };
}

sub create_constraint_generator {
  my $self = shift;
  sub {
    sub {
      my $object = shift;
      all {
        my ($attr, $template) = ($_, $self->type_template_of_attribute->{$_});
        $self->type_parameter_injector->inject($template)->check($object->$attr);
      } keys %{ $self->type_template_of_attribute };
    };
  };
}

sub create {
  my $self = shift;

  my $type = Type::Tiny->new(
    parent               => InstanceOf[ $self->class_name ],
    name                 => $self->name,
    name_generator       => sub {
      $self->name . '[' . join(', ', @{ $self->type_parameters }) . ']';
    },
    constraint_generator => $self->create_constraint_generator(),
  );

  @{ $self->type_parameters } > 0 ? $type->parameterize($self->type_parameters) : $type;
}

__PACKAGE__->meta->make_immutable;

1;
