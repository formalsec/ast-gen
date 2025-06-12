// function definition with a single parameter and an object initialization
function foo(x1) {
  let foo = { x1 };
}

// function definition with multiple parameters and an object initialization
function bar(y1, y2, y3) {
  let bar = { y1, y2, y3 };
}

// variable declaration with an object initialization containing multiple methods
let obj = { foo, bar };
// static method call on an existing identifier property (single-argument to single-parameter)
obj[foo](10);
// static method call on an existing identifier property (multi-argument to multi-parameter)
obj[bar](10, "abc", true);
// dynamic method call on a non-exiting dependent property
obj[{}](10);
// dynamic method call on a non-exiting computed property
obj[10 + "abc"](true);
// dynamic method call on non-exiting nested dynamic identifier and dependent properties
obj[baz][{}](10);
// dynamic method call with an undefined object expression
undef[bar];
