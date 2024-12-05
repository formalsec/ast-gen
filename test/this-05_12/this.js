function foo (x) {
    let obj = { bar: bar };
    obj.bar(x);
}

function bar(x) {
    this.baz = x;
    eval (this.baz);
}


module.exports.foo = foo