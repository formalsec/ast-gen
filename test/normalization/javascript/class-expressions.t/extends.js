// extended class expression without a constructor
(class extends Foo { });
// extended class expression with an empty constructor
(class extends Foo { constructor() { super(); } });
// extended class expression with a super property lookup
(class extends Foo { bar() { super.bar; } });
// extended class expression with a super property update
(class extends Foo { bar() { super.bar = 10; } });
// extended class expression with a super method call
(class extends Foo { bar() { super.bar(); } });
