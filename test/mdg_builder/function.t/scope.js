// function assignment with a single parameter
var foo = function (x) {
    // nested function declaration with a single parameter
    var bar = function (y) {
        // object initialization with values from inside and outside the scope
        ({ p1: x, p2: y });
    }
}
