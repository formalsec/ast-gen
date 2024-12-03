// variable declaration with an object initialization 
let obj = {};
// dynamic update with a non-exiting computed identifier property
obj[foo] = 10;
// dynamic update with a non-exiting computed identifier property (dependency)
let bar = {}
let dep = {}
obj[bar] = dep;
// dynamic update with a non-exiting computed literal property
obj[10 + "abc"] = 10;
// dynamic update with non-exiting computed identifier and literal properties
obj[bar][10 + "abc"] = 10;
// dynamic update with an undefined object expression
undef[foo] = 10;
