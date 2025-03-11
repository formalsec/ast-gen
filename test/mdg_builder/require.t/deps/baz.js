// module import targetting the 'foo.js' file
const foo = require('../foo')

// method call to the 'foo' method of the 'foo' module with a dependent object value 
foo.foo({});

// module exports with a function that calls the 'foo' method of the 'foo' module
module.exports = function (z) { foo.foo(z) };
