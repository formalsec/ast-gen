const dep = require('child_process');

// function declaration with a single parameter
let foo = function (x1) {
    // package sink call with a parameter argument
    dep.exec(x1);
    // package sink call with a literal argument
    dep.exec(10);
}
