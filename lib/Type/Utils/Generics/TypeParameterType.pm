package Type::Utils::Generics::TypeParameterType;
use 5.010001;
use strict;
use warnings;
use utf8;
use parent 'Type::Tiny';

use Exporter qw( import );

our @EXPORT_OK = qw( T TypeParameter );

use Carp qw( croak );
use Type::Params qw( multisig compile Invocant );
use Types::Standard -types, qw( slurpy );

sub T {
  state $c = multisig(
    [ Int ],
    [ Int, ArrayRef ],
    [ Int, slurpy Dict[ parameters => Optional[ArrayRef], optional => Optional[Bool] ] ],
  );
  my ($type_parameter_id, $parameters, $optional) = do {
    my @args = $c->(@_);
    if (${^TYPE_PARAMS_MULTISIG} == 0) {
      ($args[0], undef, 0);
    }
    elsif (${^TYPE_PARAMS_MULTISIG} == 1) {
      ($args[0], $args[1], 0);
    }
    else {
      my ($id, %options) = @_;
      ($id, $options{parameters}, $options{optional});
    }
  };

  my $type = __PACKAGE__->new(
    type_parameter_id => $type_parameter_id,
    optional          => $optional,
  );
  defined $parameters ? $type->parameterize(@$parameters) : $type;
}

{
  no warnings 'once';
  *TypeParameter = \&T;
}

sub new {
  state $c = compile(
    Invocant,
    slurpy Dict[
      type_parameter_id => Str,
      optional          => Bool,
    ],
  );
  my ($class, $args) = $c->(@_);

  my $self = $class->SUPER::new(%$args, name => 'TypeParameterType');
  $self->_initialize($args);
  $self;
}

sub _initialize {
  my ($self, $args) = @_;
  $self->{$_} = $args->{$_} for qw( type_parameter_id optional );
  $self->{constraint_generator} = $self->_build_constraint_generator;
}

sub type_parameter_id { shift->{type_parameter_id} }
sub optional { shift->{optional} }

sub constraint {
  sub { croak q{Can not use this type for type constraint. (only used to identify type parameter.) } };
}

sub _build_constraint_generator {
  my $self = shift;
  sub { $self->constraint };
}

sub parameterize {
  my $self = shift;
  my $parameterized = $self->SUPER::parameterize(@_);
  bless $parameterized, ref $self;
  $parameterized->_initialize({
    type_parameter_id => $self->type_parameter_id,
    optional          => $self->optional,
  });
  $parameterized;
}

1;
