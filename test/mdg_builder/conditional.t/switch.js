// switch statement a single case statement
switch (foo) {
    // case statement with a variable declaration containing an object
    case 10: let x1 = { p1: 10 }
}

// switch statement a multiple case statements and a default (different identifiers)
switch (bar) {
    // case statement with a variable declaration containing an object
    case 10: let y1 = { p1: 10 }
    // case statement with a variable declaration containing an object
    case "abc": let y2 = { p2: "abc" }
    // default statement with a variable declaration containing an object
    default: let y3 = { p3: true }
}

// switch statement a multiple case object updates (same identifier)
let z1 = {};
switch (bar) {
    // case statement with a static update on an object declared outside the switch
    case 10: z1.p1 = 10;
    // case statement with a static update on an object declared outside the switch
    case "abc": z1.p2 = "abc";
    // default statement with a static update on an object declared outside the switch
    default: z1.p3 = true;
}
