// invalid module exports in property foo of a single-parameter function 
module.exports.foo = function (x1) { };
// invalid module exports in property bar of a multi-parameter function 
module.exports.bar = function (x2, y2, z2) { };
// assignment expression that reassigns the module exports to a different object
module.exports = {};
// valid module export in property baz of a single-parameter function 
module.exports.baz = function (x3) { };
