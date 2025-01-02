// module import targetting the 'baz.js' file
const baz = require("./baz");

// variable declaration with an object initialization storing a method that calls the 'baz' method of the 'baz' module
let bar1 = { p: function (x) { baz(x); } };
// variable declaration with an object initialization storing a method
let bar2 = { p: function () { } };
// variable declaration with an object initialization storing an object with the 'baz' method of the 'baz' module
let bar3 = { p: { q: baz } };

// module exports with three object values
module.exports = { bar1, bar2, bar3 }
