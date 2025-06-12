// function assignment containing a return statement without an associated value
var foo = function (x1) {
  return;
};

// function assignment containing a return statement with a literal value
var bar = function (y1) {
  return 10;
};

// function assignment containing a return statement with an object value
var baz = function (z1) {
  return {};
};

// function assignment containing a return statement with an argument value
var qux = function (w1) {
  return w1;
};

// function call of a single-parameter function with a single argument
foo(10);
// function call of a single-parameter function with a single argument
bar("abc");
// function call of a single-parameter function with a single argument
baz(true);
// function call of a single-parameter function with a single argument
qux(null);
