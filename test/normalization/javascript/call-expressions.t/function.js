// function call with no arguments
foo();
// function call with a single argument
foo(10);
// function call with multiple arguments
foo(10, "abc", true);
// function call with an expression argument
foo(10 + "abc");
// function call with a computed callee
(10 + "abc")(true)
// function call with an optional callee
foo?.(10);
// function call with an optional callee and an expression argument
foo?.(10 + "abc");
