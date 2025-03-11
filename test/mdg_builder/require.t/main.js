// module import targetting the 'foo.js' file
const foo = require('./foo.js');
// module import targetting the 'deps/bar.js' file
const bar = require('./deps/bar.js');

// call to the 'foo' method of the 'foo' module with the module's 'obj' property
foo.foo(foo.obj);
// call to the 'p' method of the bar1 object, 'bar' module with the module's 'obj' property
bar.bar1.p(foo.obj);
// call to the 'q' method of the bar3.p object, 'bar' module
bar.bar3.p.q();
// call to the unknown 'bar4' method of the 'bar' module
bar.bar4();
