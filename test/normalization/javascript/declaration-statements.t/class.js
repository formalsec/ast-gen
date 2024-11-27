// class declaration without a constructor
class Foo { }
// class declaration with a multi-parameter initializing constructor
class Foo { constructor(bar, baz) { this.bar = bar; this.baz = baz; } }
// class declaration with a property and method
class Foo { bar = 10; baz() { } }
// class declaration with a static property and static method
class Foo { static bar = 10; static baz() { } }
// class declaration with an extension
class Foo extends Bar { constructor(baz) { super(baz); } };
