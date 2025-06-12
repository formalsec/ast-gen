// function call to a hoisted function declared afterwards
foo(10);
// function call to a hoisted function declared afterwards
bar("abc");

// hoisted function declaration with a single parameter
function foo(x) {
  // object initialization containing a property
  let foo1 = { x };
  // recursive function call to the current hoisted function
  foo(x);
  // function call to the hoisted function declared afterwards
  bar(x);
}

// non-hoisted function declaration with a single parameter
var foo = function (y) {
  // object initialization containing a property
  let foo2 = { y };
  // recursive function call to the current non-hoisted function
  foo(y);
};

// non-hoisted function declaration with a single parameter
var bar = function (z) {
  // object initialization containing a property
  let bar1 = { z };
  // recursive function call to the current non-hoisted function
  bar(z);
};

// hoisted function declaration with a single parameter
function bar(w) {
  // object initialization containing a property
  let bar2 = { w };
  // function call to the non-hoisted function declaration
  bar(w);
  // function call to the hoisted function declared previously
  foo(w);
}

// function call to a non-hoisted function
foo(10);
// function call to a non-hoisted function
bar("abc");
