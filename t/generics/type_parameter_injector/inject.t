use Test2::V0 qw( subtest diag ok is object prop call array item end dies like done_testing );
use Test2::Tools::Spec;

use aliased 'Type::Utils::Generics::TypeParameterInjector';
use Types::Standard -types;
use Type::Utils::Generics::TypeParameterType qw( T );
use Moose;

my $create_content_type = sub {
  my ($template, $type_params) = @_;
  my $type = shift;
};

describe 'Inject parameter into template' => sub {
  
  it 'Inject parameter' => sub {
    
    my $meta_class = Moose::Meta::Class->create_anon_class(
      attributes => [
        Moose::Meta::Attribute->new(data => (
          is       => 'ro',
          isa      => Any,
          required => 1,
        )),
      ]
    );

    my $injector = TypeParameterInjector->new(type_parameters => [Int]);
    my $Int = $injector->inject(T(0));

    is $Int->name, 'Int';
    ok $Int->check(1);
    ok !$Int->check('string');
  };

  it 'Inject parameter into union type template' => sub {
    
    my $content_class = Moose::Meta::Class->create_anon_class(
      attributes => [
        Moose::Meta::Attribute->new(data => (
          is       => 'ro',
          isa      => Any,
          required => 1,
        )),
      ]
    );

    my $user_class = Moose::Meta::Class->create_anon_class(
      attributes => [
        Moose::Meta::Attribute->new(
          name =>
          is       => 'ro',
          isa      => Str,
          required => 1,
        ),
      ]
    );
    
    my $book_class = Moose::Meta::Class->create_anon_class(
      attributes   => [
        Moose::Meta::Attribute->new(name => (
          is       => 'ro',
          isa      => Str,
          required => 1,
        )),
      ],
    );

    my $injector = TypeParameterInjector->new(type_parameters => [ InstanceOf[$book_class->name] ]);
    my $template = InstanceOf[$user_class->name] | T(0);

    my $UserOrBook = $injector->inject($template);
    is $UserOrBook, qq{InstanceOf["@{[ $user_class->name ]}"]|InstanceOf["@{[ $book_class->name ]}"]};

    my $user = $user_class->new_object(name => 'hoge');
    ok $UserOrBook->check($user);

    my $book = $book_class->new_object(name => '秘密結社のつくりかた');
    ok $UserOrBook->check($book);

    ok !$UserOrBook->check(undef);
    ok !$UserOrBook->check(755);
    ok !$UserOrBook->check(bless +{}, $content_class->name);
  };

  it 'Inject parameter into intersection type template' => sub {
    
    my $content_class = Moose::Meta::Class->create_anon_class(
      attributes => [
        Moose::Meta::Attribute->new(data => (
          is       => 'ro',
          isa      => Any,
          required => 1,
        )),
      ]
    );

    my $user_class = Moose::Meta::Class->create_anon_class(
      attributes => [
        Moose::Meta::Attribute->new(
          name =>
          is       => 'ro',
          isa      => Str,
          required => 1,
        ),
      ]
    );
    
    my $book_class = Moose::Meta::Class->create_anon_class(
      attributes   => [
        Moose::Meta::Attribute->new(title => (
          is       => 'ro',
          isa      => Str,
          required => 1,
        )),
      ],
    );

    my $injector = TypeParameterInjector->new(type_parameters => [ InstanceOf[$book_class->name] ]);
    my $template = InstanceOf[$user_class->name] & T(0);

    my $UserAndBook = $injector->inject($template);
    is $UserAndBook, qq{InstanceOf["@{[ $user_class->name ]}"]&InstanceOf["@{[ $book_class->name ]}"]};

    my $author_class = Moose::Meta::Class->create_anon_class(
      superclasses => [ $user_class->name, $book_class->name ],
    );

    my $author = $author_class->new_object(
      title => '秘密結社のつくりかた',
      name  => '志摩リン',
    );
    ok $UserAndBook->check($author);

    my $user = $user_class->new_object(name => 'hoge');
    ok !$UserAndBook->check($user);

    my $book = $book_class->new_object(title => '秘密結社のつくりかた');
    ok !$UserAndBook->check($book);
  };

  it 'Template has multiple type parameter type' => sub {

    my $content_class = Moose::Meta::Class->create_anon_class(
      attributes => [
        Moose::Meta::Attribute->new(
          data =>
          is       => 'ro',
          isa      => Tuple[Str, Str],
          required => 1,
        ),
      ]
    );

    my $injector = TypeParameterInjector->new(type_parameters => [Int]);
    my $template = Tuple[T(0), T(0)];

    my $TupleIntInt = $injector->inject($template);
    is $TupleIntInt->display_name, 'Tuple[Int,Int]';

    ok $TupleIntInt->check([1, 2]);
    ok !$TupleIntInt->check([1, "???"]);
    ok !$TupleIntInt->check(["???", 0]);
    ok !$TupleIntInt->check(["???", "///"]);
  };

  it 'Template has each different multiple type parameter type' => sub {

    my $content_class = Moose::Meta::Class->create_anon_class(
      attributes => [
        Moose::Meta::Attribute->new(
          data =>
          is       => 'ro',
          isa      => Tuple[Str, Str, Str],
          required => 1,
        ),
      ]
    );

    my $injector = TypeParameterInjector->new(
      type_parameters => [
        Enum[qw( blue red)],
        Enum[qw( male female )],
        Enum[qw( true false )],
      ],
    );
    my $template = Tuple[T(0), T(1), T(2)];

    my $TupleColorSexBool = $injector->inject($template);
    is(
      $TupleColorSexBool->display_name,
      'Tuple[Enum["blue","red"],Enum["male","female"],Enum["true","false"]]'
    );

    ok $TupleColorSexBool->check(['red', 'male', 'true']);
    ok !$TupleColorSexBool->check(['male', 'male', 'false']);
    ok !$TupleColorSexBool->check(['???', '!!!', '^^^']);
  };

  it 'Type parameter type has parameter' => sub {

    my $content_class = Moose::Meta::Class->create_anon_class(
      attributes => [
        Moose::Meta::Attribute->new(
          'data',
          is       => 'ro',
          isa      => ArrayRef,
          required => 1,
        ),
      ]
    );

    my $injector = TypeParameterInjector->new(type_parameters => [Tuple]);
    my $template = ArrayRef[ T(0, [Int, Int]) ];

    my $ArrayRefTupleIntInt = $injector->inject($template);
    is $ArrayRefTupleIntInt->display_name, 'ArrayRef[Tuple[Int,Int]]';

    ok $ArrayRefTupleIntInt->check([ [1, 2], [3, 5], [8, 13], [21, 34] ]);
    ok !$ArrayRefTupleIntInt->check([ ['A'], [3, 5] ]);
    ok !$ArrayRefTupleIntInt->check([ +{ a => 1 } ]);
  };

  it 'Type parameter type has type parameter type' => sub {

    my $content_class = Moose::Meta::Class->create_anon_class(
      attributes => [
        Moose::Meta::Attribute->new(
          data =>
          is       => 'ro',
          isa      => ArrayRef,
          required => 1,
        ),
      ]
    );

    my $injector = TypeParameterInjector->new(
      type_parameters => [ Map, Enum[qw( blue red green )], Int ],
    );
    my $template = ArrayRef[ T(0, [ T(1), T(2) ]) ];

    my $ArrayRefMapColorInt = $injector->inject($template);
    is $ArrayRefMapColorInt->display_name, 'ArrayRef[Map[Enum["blue","red","green"],Int]]';

    ok $ArrayRefMapColorInt->check([ +{ green => 3, red => 2 } ]);
    ok !$ArrayRefMapColorInt->check([ +{ brown => 3 } ]);
    ok !$ArrayRefMapColorInt->check([ [1, 2] ]);
  };

  it 'Type parameter type has parameter, and the parameter has type parameter type' => sub {

    my $content_class = Moose::Meta::Class->create_anon_class(
      attributes => [
        Moose::Meta::Attribute->new(
          data =>
          is       => 'ro',
          isa      => Any,
          required => 1,
        ),
      ]
    );

    my $injector = TypeParameterInjector->new(type_parameters => [ ArrayRef, Int, Int ]);
    my $template = T(0, [ Tuple[ T(1), T(2) ] ]);

    my $ArrayRefTupleIntInt =
      $injector->inject( $template );
    is $ArrayRefTupleIntInt->display_name, 'ArrayRef[Tuple[Int,Int]]';

    ok $ArrayRefTupleIntInt->check([ [0, 1], [1, 2] ]);
    ok !$ArrayRefTupleIntInt->check([ ['A', 1], [1, 'B'] ]);
  };

};

done_testing;
