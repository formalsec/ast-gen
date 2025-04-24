// function assignment with a simple parameter and an object parameter
let foo = function (x, y) {
    // static lookup on a non-existing identifier property
    let z = y.p;
}

// module export in property foo of a multi-parameter function 
module.exports.foo = foo
// module export in property bar of an object with a nested object
module.exports.foo = { q: {} }
