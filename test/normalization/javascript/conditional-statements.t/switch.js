// switch statement with no consequents
switch (foo) { }
// switch statement with a single empty consequent
switch (foo) { case 10: }
// switch statement with a single non-empty consequent
switch (foo) { case 10: x; }
// switch statement with multiple empty consequents
switch (foo) { case 10: case "abc": case true: }
// switch statement with multiple non-empty consequents
switch (foo) { case 10: x; case "abc": y; case true: z; }
// switch statement with a default consequent
switch (foo) { case 10: x; default: y; }
// switch statement with a default consequent in the middle
switch (foo) { case 10: x; default: y; case "abc": z }
// switch statement with a nested switch statement
switch (foo) { case 10: switch (bar) { case "abc": y; } case true: z; }
// switch statement with a computed discriminant
switch (foo + bar) { case 10: x }
// switch statement with a computed case test
switch (foo) { case (10 + "abc"): x; }
// switch statement with a computed discriminant and case test
switch (foo + bar) { case (10 + "abc"): x; }
