// if statement with a consequent object initialization
if (true) { let x1 = { p1: 10 } }
// if statement with a consequent and alternate object initialization
if (true) { let y1 = { p1: 10 } } else { let y2 = { p2: "abc" } }
// if statement with a consequent and alternate object initialization (same identifier)
if (true) { let z1 = { p1: 10 } } else { let z1 = { p2: "abc" } }
({}.p = z);
// if statement with a consequent and alternate object update (same identifier)
let w1 = {};
if (true) { w1.p1 = 10 } else { w1.p2 = "abc"; }
({}.p = w1);
