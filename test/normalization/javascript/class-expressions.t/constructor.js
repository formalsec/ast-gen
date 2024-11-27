// class expression without a constructor
(class { });
// class expression with an empty constructor
(class { constructor() { } });
// class expression with an single-parameter constructor
(class { constructor(foo) { } });
// class expression with a multi-parameter constructor
(class { constructor(foo, bar, baz) { } });
// class expression with a initializing constructor
(class { constructor(foo) { this.foo = foo } });
