// function assignment with a single parameter
var foo = function (x1) { }
// function assignment with multiple parameters
var bar = function (y1, y2, y3) { }
// function call of a single-parameter function with a single argument 
foo(10);
// function call of a multi-argument function with a single argument 
bar(10);
// function call of a single-argument function with multiple arguments 
foo(10, "abc", true);
// function call of a multi-argument function with multiple arguments 
bar(10, "abc", true);
// function call with an undefined function callee
baz(10);
