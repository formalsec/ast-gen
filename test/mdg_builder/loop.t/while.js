// while statement with an object initialization
while (true) { let x1 = { p1: 10 } }
// while statement with out of order object initializations
while (true) { let y1 = { p1: y2 }; let y2 = { p2: y3 }; let y3 = { p3: 10 } }
