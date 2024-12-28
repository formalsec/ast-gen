// function call to a hoisted function declared afterwards
foo(10);
// function call to a hoisted function declared afterwards
bar("abc");

// hoisted function declaration with a single parameter
function foo(p) {
    // recursive function call to the current hoisted function
    foo(p);
    // function call to the hoisted function declared afterwards
    bar(p);
}

// non-hoisted function declaration with a single parameter
var foo = function (p) {
    // recursive function call to the current non-hoisted function
    foo(p);
}

// non-hoisted function declaration with a single parameter
var bar = function (p) {
    // recursive function call to the current non-hoisted function
    bar(p);
}

// hoisted function declaration with a single parameter
function bar(p) {
    // function call to the non-hoisted function declaration
    bar(p);
    // function call to the hoisted function declared previously
    foo(p);
}

// function call to a non-hoisted function
foo(10);
// function call to a non-hoisted function
bar("abc");
