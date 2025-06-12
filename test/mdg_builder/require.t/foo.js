// variable declaration with an object initialization
let obj = { foo: 10 };
// function declaration with a single parameter
let foo = function (x) {
  ({}).p = x;
};

// module exports of an object value and a single-parameter function
module.exports = { obj, foo };
