// constructor call with no arguments
new foo();
// constructor call with a single argument
new foo(10);
// constructor call with multiple arguments
new foo(10, "abc", true);
// constructor call with an expression argument
new foo(10 + "abc");
// constructor call with a computed callee
new (10 + "abc")(true)
