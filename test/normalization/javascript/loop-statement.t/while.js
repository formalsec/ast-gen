// while statement with an empty inline body statement
while (10);
// while statement with an empty block body statement
while (10) { }
// while statement with a non-empty inline body statement
while (10) x;
// while statement with a non-empty block body statement
while (10) { x; }
// while statement with a nested while statement
while (10) { while ("abc") x; }
// while statement with a computed test
while (10 + "abc" == true) x;
