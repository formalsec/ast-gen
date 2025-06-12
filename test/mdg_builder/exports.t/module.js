// invalid module exports in property foo of a single-parameter function
module.exports.foo = function (x1) {
  let foo = { x1 };
};

// assignment expression that reassigns the module exports to a different object
module.exports = {};

// valid module exports in property bar of a single-parameter function
module.exports.bar = function (y1) {
  let bar = { y1 };
};

// valid module exports in property baz of a multi-parameter function
module.exports.baz = function (z1, z2, z3) {
  let baz = { z1, z2, z3 };
};
