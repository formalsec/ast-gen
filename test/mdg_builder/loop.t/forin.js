// forin statement with an object initialization
for (x0 in {}) { let x1 = { p1: 10 } }
// forin statement with out of order object initializations
for (y0 in {}) { let y1 = { p1: y2 }; let y2 = { p2: y3 }; let y3 = { p3: 10 } }
