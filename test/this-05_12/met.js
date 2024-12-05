let obj = {};

function foo(obj) {
    sink(obj.foo);
}

function bar(x) {
    obj.foo = x;
    foo(obj);
} 
