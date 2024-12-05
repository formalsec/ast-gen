function foo(x) {
    let obj = {};
    let obj2 = obj[x];
    bar(obj2);
}

function bar(obj, y, z) {
    baz(obj, y, z)
}

function baz(obj, y, z) {
    obj[y] = z;
}

module.exports.foo = foo;