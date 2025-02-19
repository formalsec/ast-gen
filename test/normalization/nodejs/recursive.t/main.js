function foo() { }
module.exports = { foo }

const dep = require('./dependency.js');
dep.foo();
