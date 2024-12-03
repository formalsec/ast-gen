// variable declaration with an object initialization 
let obj = {};
// dynamic lookup with a non-exiting computed identifier property
obj[foo];
// dynamic lookup with a non-exiting computed identifier property (dependency)
let bar = {}
obj[bar];
// dynamic lookup with a non-exiting computed literal property
obj[10 + "abc"];
// dynamic lookup with non-exiting computed identifier and literal properties
obj[bar][10 + "abc"];
// dynamic lookup with an undefined object expression
undef[bar];
