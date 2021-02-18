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

Type::Utils::Generics - It's new $module

=head1 SYNOPSIS

    use Type::Utils::Generics;

=head1 DESCRIPTION

Type::Utils::Generics is ...

=head1 LICENSE

Copyright (C) ybrliiu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ybrliiu E<lt>raian@reeshome.orgE<gt>

=cut

