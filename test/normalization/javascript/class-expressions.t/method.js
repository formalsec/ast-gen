// class expression with a method
(class { foo() { }; });
// class expression with a literal key method
(class { 10() { }; });
// class expression with a computed key method
(class { [foo]() { }; });
// class expression with a static method
(class { static foo() { }; });
// class expression with a getter
(class { get foo() { }; });
// class expression with a literal key getter
(class { get 10() { }; });
// class expression with a computed key getter
(class { get [foo]() { }; });
// class expression with a static getter
(class { static get foo() { }; });
// class expression with a setter
(class { set foo(x) { }; });
// class expression with a literal key setter
(class { set 10(x) { }; });
// class expression with a computed key setter
(class { set [foo](x) { }; });
// class expression with a static setter
(class { static set foo(x) { }; });
// class expression with a method, getter, and setter
(class { foo() { } get bar() { }; set baz(x) { }; });
// class expression with a static method, getter, and setter
(class { static foo() { } static get bar() { }; static set baz(x) { }; });
