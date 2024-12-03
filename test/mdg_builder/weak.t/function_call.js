// function declaration with a single parameter
let foo = function (x1) { }
// function declaration with multiple parameters
let bar = function (y1, y2, y3) { }
// variable declaration with a weak function assignment
let baz = true ? foo : bar;
// function call with a single argument on a weak function
baz(10);
// function call with multiple arguments on a weak function
baz(10, "abc", true);
