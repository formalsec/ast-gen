// while statement with a single object initialization
while (true) {
  var x1 = { p1: 10 };
}

// while statement with multiple out of order object initializations
while (true) {
  var y1 = { p1: y2 };
  var y2 = { p2: y3 };
  var y3 = { p3: 10 };
  var y4 = { p4: y1 };
}

// while statement with a nested loop and multiple out of order object initializations
while (true) {
  while (true) {
    var z1 = { p1: z2 };
    var z2 = { p2: z3 };
  }
  var z3 = { p3: 10 };
  var z4 = { p4: z1 };
}

// while statement with that iteratively applies an operator
var w1 = {};
while (true) {
  w1.p1 = w1.p1 + 10;
}
