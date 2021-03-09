package Type::Utils::Generics::Subroutine;
use 5.010001;
use Moo;
use utf8;
use namespace::autoclean;

use aliased 'Type::Utils::Generics::TypeParameterInjector';
use List::Util qw( all );
use Carp::Assert qw( assert DEBUG );
use Types::Standard -types;
use Types::TypedCodeRef ();
use Types::TypedCodeRef::Factory;

my $TypeConstraint = InstanceOf['Type::Tiny'];
my $ParamsTypes    = $TypeConstraint | ArrayRef[$TypeConstraint] | HashRef[$TypeConstraint];
my $ReturnTypes    = $TypeConstraint | ArrayRef[$TypeConstraint];

has name => (
  is       => 'ro',
  isa      => Maybe[Str],
  required => 1,
);

has type_template_of_parameters => (
  is       => 'ro',
  isa      => $ParamsTypes,
  required => 1,
);

has type_template_of_returns => (
  is       => 'ro',
  isa      => $ReturnTypes,
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

  my @templates = (
    ref $self->type_template_of_parameters eq 'HASH' ? values %{ $self->type_template_of_parameters }
      : ref $self->type_template_of_parameters eq 'ARRAY' ? @{ $self->type_template_of_parameters }
      : $self->type_template_of_parameters,
    ref $self->type_template_of_returns eq 'ARRAY' ? @{ $self->type_template_of_returns }
      : $self->type_template_of_returns,
  );

  all { $self->type_parameter_injector->find_type_parameter_type($_) } @templates;
}

sub create {
  my $self = shift;

  my $params_types = do {
    my $templates = $self->type_template_of_parameters;
    if ( ref $templates eq 'HASH' ) {
      +{ map { $_ => $self->type_parameter_injector->inject($templates->{$_}) } keys %$templates };
    }
    elsif ( ref $templates eq 'ARRAY' ) {
      [ map { $self->type_parameter_injector->inject($_) } @$templates ];
    }
    else {
      $self->type_parameter_injector->inject($templates)
    }
  };

  my $return_types = do {
    my $templates = $self->type_template_of_returns;
    if ( ref $templates eq 'ARRAY' ) {
      [ map { $self->type_parameter_injector->inject($_) } @$templates ];
    }
    else {
      $self->type_parameter_injector->inject($templates)
    }
  };

  my $factory = Types::TypedCodeRef::Factory->new(
    defined $self->name ? ( name => $self->name ) : (),
    # TODO: name_generator も指定したい・・・
    sub_meta_finders => [\&Types::TypedCodeRef::get_sub_meta_from_sub_wrap_in_type],
  );

  $factory->create->parameterize($params_types => $return_types);
}

__PACKAGE__->meta->make_immutable;

1;
