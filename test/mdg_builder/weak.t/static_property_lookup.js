// variable declaration with a weak object initialization 
let obj = true ? {} : {};
// static lookup with a non-exiting identifier property
obj.foo;
// static lookup with non-exiting nested identifier properties
obj.bar.baz;
// static lookup with a non-existing null property
obj[null];
// static lookup with a non-existing string literal property
obj["abc"];
// static lookup with a non-existing number literal property
obj[10];
// static lookup with an undefined object expression
undef.foo;
