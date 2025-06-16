// forin statement with a single object initialization
for (x in {}) {
  var x1 = { p1: 10 };
}

// forin statement with multiple out of order object initializations
for (y in {}) {
  var y1 = { p1: y2 };
  var y2 = { p2: y3 };
  var y3 = { p3: 10 };
  var y4 = { p4: y1 };
}

// forin statement with a nested loop and multiple out of order object initializations
for (z in {}) {
  for (z0 in {}) {
    var z1 = { p1: z2 };
    var z2 = { p2: z3 };
  }
  var z3 = { p3: 10 };
  var z4 = { p4: z1 };
}

// forin statement with that iteratively applies an operator
var w1 = {};
for (w in {}) {
  w1.p1 = w1.p1 + 10;
}
