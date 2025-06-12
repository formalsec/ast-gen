// module import targetting the 'baz.js' file
const baz = require("./baz");

// variable declaration with an object initialization storing a single-parameter method
// that calls the 'baz' method of the 'baz' module
let bar1 = {
  p: function (y) {
    baz(y);
  },
};

// variable declaration with an object initialization storing a no-parameter empty method
let bar2 = { p: function () {} };
// variable declaration with an object initialization storing an object with the 'baz' method of the 'baz' module
let bar3 = { p: { q: baz } };

// exports in property bar1 of a single-parameter function
exports.bar1 = bar1;
// exports in property bar2 of a no-parameter function
exports.bar2 = bar2;
// exports in property bar3 of an object
exports.bar3 = bar3;
