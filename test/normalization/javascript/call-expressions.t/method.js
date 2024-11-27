// static method call with no arguments
foo.bar();
// static method call with a single argument
foo.bar(10);
// static method call with multiple arguments
foo.bar(10, "abc", true);
// static method call with an expression argument
foo.bar(10 + "abc");
// dynamic method call with an identifier property
foo[bar](10);
// dynamic method call with a computed property
foo[10 + "abc"](true);
// method call with an optional callee
foo.bar?.(10);
// method call with an optional callee and an expression argument
foo.bar?.(10 + "abc");
