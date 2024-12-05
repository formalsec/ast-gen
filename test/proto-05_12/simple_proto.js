function foo(x, y, z) {
    let obj = {};
    let obj2 = obj[x];
    obj2[y] = z;  
}

module.exports.foo = foo;