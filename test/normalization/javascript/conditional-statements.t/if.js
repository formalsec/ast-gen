// if statement with an empty inline consequent statement
if (10);
// if statement with an empty block consequent statement
if (10) { }
// if statement with a non-empty inline consequent statement
if (10) x;
// if statement with a non-empty block consequent statement
if (10) { x; }
// if statement with an alternate inline statement
if (10) x; else y;
// if statement with an alternate block statement
if (10) { x; } else { y; }
// if statement with an else if inline statement
if (10) x; else if ("abc") y; else z;
// if statement with an else if block statement
if (10) { x; } else if ("abc") { y; } else { z; }
// if statement with a nested if statement
if (10) { if ("abc") x; else y; } else z;
// if statement with a computed test
if (10 + "abc" == true) { x }
