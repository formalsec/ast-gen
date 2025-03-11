// export in property foo of a single-parameter function 
exports.foo = function (x1) { };
// export in property bar of a multi-parameter function 
exports.bar = function (x2, y2, z2) { };
// assignment expression that reassigns the export value to a different object
exports = {};
// non-export in property baz of a single-parameter function 
exports.baz = function (x3) { };
