// forof statement with an object initialization
for (x0 of {}) { let x1 = { p1: 10 } }
// forof statement with out of order object initializations
for (y0 of {}) { let y1 = { p1: y2 }; let y2 = { p2: y3 }; let y3 = { p3: 10 } }
