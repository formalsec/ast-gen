// variable declaration with an object initialization
let obj = {};
// dynamic update on a non-exiting dynamic identifier property
obj[foo] = 10;
// dynamic update on a non-exiting dynamic identifier property with a dependent right value
obj[bar] = {};
// dynamic update on non-exiting nested identifier properties
obj[foo][bar] = 10;
// dynamic update on a non-exiting dependent property
obj[{}] = 10;
// dynamic update on a non-exiting computed property
obj[10 + "abc"] = true;
// dynamic update on non-exiting nested dynamic identifier and dependent properties
obj[baz][{}] = 10;
// dynamic update on an undefined object expression
undef[foo] = 10;
