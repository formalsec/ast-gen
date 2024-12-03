// variable declaration with a weak object initialization 
let obj = true ? {} : {};
// static update with a non-exiting identifier property
obj.foo = 10;
// static update with a non-exiting identifier property (dependency)
let dep = {}
obj.foo = dep;
// static update with non-exiting nested identifier properties
obj.bar.baz = 10;
// static update with a non-existing null property
obj[null] = 10;
// static update with a non-existing string literal property
obj["abc"] = 10;
// static update with a non-existing number literal property
obj[10] = 10;
// static update with an undefined object expression
undef.foo = 10;
