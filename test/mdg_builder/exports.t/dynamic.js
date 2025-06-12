// static module exports in property foo of a single-parameter function
module.exports.foo = function (x1) {
  let foo = { x1 };
};

// dynamic module exports in property bar of a multi-parameter function
module[export_prop].bar = function (y1, y2, y3) {
  let bar = { y1, y2, y3 };
};

// dynamic module exports in a dynamic property of a single-parameter function
module[export_prop][baz] = function (z1) {
  let baz = { z1 };
};
