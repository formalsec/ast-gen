// variable declaration with an object initialization containing multiple methods
let obj = { foo: function (x1) { }, bar: function (y1, y2, y3) { } };
// method call with a single argument of a single-parameter method
obj.foo(10);
// method call with a single argument of a multi-argument method
obj.bar(10);
// method call with multiple arguments of a multi-argument method
obj.bar(10, "abc", true);
// method call with multiple arguments of a single-argument function
obj.foo(10, "abc", true);
// method call with an undefined caller expression
obj.baz(10);
// method call with an undefined object expression
undef.foo;
