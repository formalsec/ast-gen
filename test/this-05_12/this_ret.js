function foo (x) {
    let obj = { bar: bar };
    obj.bar(x);
    eval (this.baz);
}

function bar(x) {
    this.baz = x;
}


module.exports.foo = foo