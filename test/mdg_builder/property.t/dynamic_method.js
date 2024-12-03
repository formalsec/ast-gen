// variable declaration with an object initialization containing multiple methods
let obj = { foo: function (x1) { }, bar: function (y1, y2, y3) { } };
// method call with a single argument of a computed identifier method
obj[foo](10);
// method call with multiple arguments of a computed identifier property (dependency)
let bar = {};
obj[bar](10, "abc", true);
// method call with a non-exiting computed literal property
obj[10 + "abc"](10);
// method call with a non-exiting computed identifier and literal properties
obj[bar][10 + "abc"](10);
// method call with an undefined object expression
undef[bar];
