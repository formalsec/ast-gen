// function assignment with a single parameter and an inner dependency
var foo = function (x1) { ({ p1: x1 }); }
// function assignment with multiple parameters and inner dependencies
var bar = function (y1, y2, y3) { ({ p1: y1, p2: y2, p3: y3 }); }
// function assignment with a single object parameter whose property is read
var baz = function (z1) { ({ p: z1.p1 }); }
// function assignment with a single object parameter whose property is read and used
var qux = function (w1) { ({}).q = ({ p: w1.p1 }).p } 
