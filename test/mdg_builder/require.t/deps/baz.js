// module import targetting the npm 'path' module
const npm = require('path');
// method call to the 'basename' method of the 'npm' module with a literal value
npm.basename("abc");

// module import targetting the 'foo.js' file
const foo = require('../foo')

// module exports with a function that calls the 'foo' method of the 'foo' module
module.exports = function (z) { foo.foo(z) };
