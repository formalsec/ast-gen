// variable declaration with a weak object initialization 
let obj = true ? {} : {};
// static update on a non-exiting identifier property
obj.foo = 10;
// static update on a non-exiting identifier property with a dependent right value
obj.bar = {};
// static update on non-exiting nested identifier properties
obj.bar.baz = 10;
// static update on a non-existing number literal property
obj[10] = 10;
// static update on a non-existing string literal property
obj["abc"] = 10;
// static lookup on a non-existing null literal property
obj[null] = 10;
