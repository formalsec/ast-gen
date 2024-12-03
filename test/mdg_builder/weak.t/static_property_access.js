// variable declaration with a weak object initialization 
let obj = true ? {} : {};
// static update with a non-exiting identifier property
obj.foo = 10;
// static lookup with an existing identifier property
obj.foo;
// static lookup with an non-existing identifier property
obj.bar;
// static update with an existing identifier property
obj.foo = 10;
// static update with an non-existing identifier property
obj.bar = 10;
