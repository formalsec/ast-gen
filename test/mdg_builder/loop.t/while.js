// while statement with a single object initialization
while (true) { let x1 = { p1: 10 } }
// while statement with multiple out of order object initializations
while (true) { let y1 = { p1: y2 }; let y2 = { p2: y3 }; let y3 = { p3: 10 }; let y4 = { p4: y1 } }
// while statement with a nested loop and multiple out of order object initializations
while (true) { while (true) { let z1 = { p1: z2 }; let z2 = { p2: z3 }; } let z3 = { p3: 10 }; let z4 = { p4: z1 } }
