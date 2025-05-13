// function assignment with a single parameter
var foo = function (x1) { }
// function assignment with multiple parameters
var bar = function (y1, y2, y3) { }
// new call of a single-parameter function with a single argument 
new foo(10);
// new call of a multi-argument function with a single argument 
new bar(10);
// new call of a single-argument function with multiple arguments 
new foo(10, "abc", true);
// new call of a multi-argument function with multiple arguments 
new bar(10, "abc", true);
// new call with an undefined function callee
new baz(10);
