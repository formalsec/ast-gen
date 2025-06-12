// exports in property foo of a single-parameter function
exports.foo = function (x1) {
  let foo = { x1 };
};

// module exports in property bar of a multi-parameter function
module.exports.bar = function (y1, y2, y3) {
  let bar = { y1, y2, y3 };
};
