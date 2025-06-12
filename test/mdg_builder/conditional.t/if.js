// if statement with a consequent object initialization
if (true) x1 = { p1: 10 };
x = { q1: x1 };

// if statement with a consequent and alternate object initialization (different identifiers)
if (true) y1 = { p1: 10 };
else y2 = { p2: "abc" };
y = { q1: y1, q2: y2 };

// if statement with a consequent and alternate object initialization (same identifier)
if (true) z1 = { p1: 10 };
else z1 = { p2: "abc" };
z = { q1: z1 };

// if statement with a consequent and alternate object update (same identifier)
let w1 = {};
if (true) w1.p1 = 10;
else w1.p2 = "abc";
w = { q1: w1 };
