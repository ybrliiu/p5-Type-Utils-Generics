requires 'perl', '5.010001';
requires 'Sub::Util', '1.55';
requires 'Type::Tiny', '1.010004';
requires 'Moo', '2.004004';
requires 'Type::Tiny', '2.004000';
requires 'Carp::Assert', '0.21';
requires 'aliased', '0.34';
requires 'namespace::autoclean', '0.29';
requires 'Sub::WrapInType', '0.05';
requires 'Types::TypedCodeRef', '0.07';

on 'test' => sub {
    requires 'Test2::Suite', '0.000138';
    requires 'Moose', '2.2014';
};

