// function assignment with a single parameter
let foo = function (x1) {
  // sink call with a parameter argument
  eval(x1);
  // sink call with a literal argument
  eval(10);
};

// function call of a single-parameter function with a single argument
foo(10);
// function call of a single-parameter function with a single argument (tainted)
foo("tainted");
