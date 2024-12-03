// function declaration with a single parameter
function foo(x) {
    // nested function declaration with a single parameter
    function bar(y) {
        // object initialization with names from inside and outside the scope
        ({ p1: x, p2: y });
    }
}