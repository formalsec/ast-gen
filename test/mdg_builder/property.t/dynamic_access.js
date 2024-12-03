// variable declaration with an object initialization 
let obj = {};
// dynamic update with a non-exiting identifier property
obj[foo] = 10;
// dynamic lookup with an existing identifier property
obj[foo];
// dynamic lookup with an non-existing identifier property
obj[bar];
// dynamic update with an existing identifier property
obj[foo] = 10;
// dynamic update with an non-existing identifier property
obj[bar] = 10;
