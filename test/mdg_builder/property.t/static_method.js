// variable declaration with an object initialization containing multiple methods
let obj = { foo: function (x1) { }, bar: function (y1, y2, y3) { } };
// static method call on an existing identifier property (single-argument to single-parameter)
obj.foo(10);
// static method call on an existing identifier property (multi-argument to multi-parameter)
obj.bar(10, "abc", true);
// static method call with an undefined caller expression
obj.baz(10);
// static method call with an undefined object expression
undef.foo;
