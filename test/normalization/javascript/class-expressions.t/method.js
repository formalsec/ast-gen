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
(class { set foo(bar) { }; });
// class expression with a literal key setter
(class { set 10(bar) { }; });
// class expression with a computed key setter
(class { set [foo](bar) { }; });
// class expression with a static setter
(class { static set foo(bar) { }; });
// class expression with a getter and setter
(class { get foo() { }; set foo(bar) { }; });
// class expression with a static getter and setter
(class { static get foo() { }; static set foo(bar) { }; });
