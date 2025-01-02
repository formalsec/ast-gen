// variable declaration with an object initialization 
let obj = { foo: 10 };
// function declaration with a single parameter
function foo(x) { ({}.p = x); }

// module exports with an object value and a single-parameter function
module.exports = { obj, foo }
