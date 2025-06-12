// function assignment with a single parameter and an object initialization
var foo = function (x1) {
  this.x1 = x1;
};

// function assignment with multiple parameters and an object initialization
var bar = function (y1, y2, y3) {
  this.y1 = y1;
  this.y2 = y2;
  this.y3 = y3;
};

// new call of a single-parameter function with a single argument
let o1 = new foo(10);
// new call of a multi-argument function with a single argument
let o2 = new bar(10);
// new call of a single-argument function with multiple arguments
let o3 = new foo(10, "abc", true);
// new call of a multi-argument function with multiple arguments
let o4 = new bar(10, "abc", true);
// new call with an undefined function callee
let o5 = new baz(10);
