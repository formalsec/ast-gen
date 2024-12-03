// function assignment with a single parameter and an inner dependency
let foo = function (x1) { ({ p1: x1 }); }
// function assignment with multiple parameters and inner dependencies
let bar = function (y1, y2, y3) { ({ p1: y1, p2: y2, p3: y3 }); }
// function assignment with a single object parameter
let baz = function (z1) { ({}.p) = z1.p1; }
// function assignment with a single parameter stored in and read from an object
let qux = function (w1) { ({}.p) = ({ p1: w1 }).p1; }
