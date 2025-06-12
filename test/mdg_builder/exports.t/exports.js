// valid exports in property foo of a single-parameter function
exports.foo = function (x1) {
  let foo = { x1 };
};
// valid exports in property bar of a multi-parameter function
exports.bar = function (y1, y2, y3) {
  let bar = { y1, y2, y3 };
};

// assignment expression that reassigns the exports value to a different object
exports = {};

// invalid exports in property baz of a single-parameter function
exports.baz = function (z1) {
  let baz = { z1, z2, z3 };
};
