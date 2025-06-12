// variable declaration with a weak object initialization
let obj = true ? {} : {};
// static update on a non-exiting identifier property
obj.foo = 10;
// static update on an exiting identifier property with a weak right value
obj.foo = true ? {} : {};
// variable declaration with an object initialization
let obj2 = {};
// static update on a non-existing identifier property with a weak property value
obj2.bar = obj.foo;
