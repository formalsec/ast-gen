// variable declaration with an object initialization
let obj = {};
// dynamic lookup on a non-exiting dynamic identifier property
obj[foo];
// dynamic lookup on non-exiting nested identifier properties
obj[foo][bar];
// dynamic lookup on a non-exiting dependent property
obj[{}];
// dynamic lookup on a non-exiting computed property
obj[10 + "abc"];
// dynamic lookup on non-exiting nested dynamic identifier and dependent properties
obj[bar][{}];
// dynamic lookup on an undefined object expression
undef[bar];
