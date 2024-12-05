// function declaration with a single parameter
let bar = function (x1) {
    // static lookup with a this expression
    let x = this.foo;
    // method call with a this expression
    let y = this.bar("abc");
}

// variable declaration with an object initialization containing a property and a method
let obj = { foo: 10, bar: bar };
// function call with a single argument of a single-parameter function
bar(10);
// method call with a single argument of a single-parameter method
obj.bar(10);
