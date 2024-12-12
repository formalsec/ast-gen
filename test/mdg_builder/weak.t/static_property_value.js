// variable declaration with a weak object initialization 
let obj = true ? {} : {};
// static update with a weak object and a strong property value
obj.foo = 10;
// static update with a weak object and a weak property value
obj.foo = (true ? {} : {});
// variable declaration with an object initialization 
let obj2 = {};
// static lookup with a weak object and weak property value
obj2.bar = obj.foo;
