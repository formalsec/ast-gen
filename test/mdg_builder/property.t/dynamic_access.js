// variable declaration with an object initialization
let obj = {};
// dynamic update on a non-exiting dynamic identifier property
obj[foo] = 10;
// dynamic update on a non-exiting dynamic identifier property with a dependent right value
obj[bar] = {};
// dynamic update on non-exiting nested dynamic identifier property
obj[baz][p] = 10;
// static update on a non-exiting identifier property with an assigned property value
obj[qux] = obj[foo];
// static update on an exiting identifier property with an assigned property value
obj[qux] = obj[bar];
