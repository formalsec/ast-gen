// static module export in property foo of a single-parameter function 
module.exports.foo = function (x1) { };
// dynamic module export in property bar of a multi-parameter function 
module[export_prop].bar = function (x2, y2, z2) { };
// dynamic module export in a dynamic property of a single-parameter function 
module[export_prop][baz] = function (x3) { };
