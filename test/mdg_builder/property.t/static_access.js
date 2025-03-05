// variable declaration with an object initialization
let obj = {};
// static update on a non-exiting identifier property
obj.foo = 10;
// static update on a non-exiting identifier property with a dependent right value
obj.bar = {};
// static update on non-exiting nested identifier properties
obj.baz.p = 10;
// static update on a non-exiting identifier property with an assigned property value
obj.qux = obj.foo;
// static update on an exiting identifier property with a assigned property value
obj.qux = obj.bar;
