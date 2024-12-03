// function declaration with a single parameter
let foo = function (x1) { }
// function declaration with multiple parameters
let bar = function (y1, y2, y3) { }
// function call with a single argument of a single-parameter function
foo(10);
// function call with a single argument of a multi-argument function
bar(10);
// function call with multiple arguments of a multi-argument function
bar(10, "abc", true);
// function call with multiple arguments of a single-argument function
foo(10, "abc", true);
// function call with an undefined function callee
baz(10);
