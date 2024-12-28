// variable declaration with an object initialization
let obj = {};
// static lookup on a non-exiting identifier property
obj.foo;
// static lookup on non-exiting nested identifier properties
obj.bar.baz;
// static lookup on a non-existing number literal property
obj[10];
// static lookup on a non-existing string literal property
obj["abc"];
// static lookup on a non-existing null literal property
obj[null];
// static lookup on an undefined object expression
undef.foo;
