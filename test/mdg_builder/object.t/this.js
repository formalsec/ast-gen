// function assignment with a single parameter
var bar = function (x1) {
    // static lookup on a this expression
    let x = this.foo;
    // method call on a this expression with a single parameter
    let y = this.bar("abc");
}

// variable declaration with an object initialization containing a property and a method
let obj = { foo: 10, bar: bar };
// function call of a single-parameter function with a single argument
bar(10);
// method call of a single-parameter method with a single argument
obj.bar(10);
