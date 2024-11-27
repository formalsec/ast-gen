// do while statement with an empty inline body statement
do; while (10)
// do while statement with an empty block body statement
do { } while (10)
// do while statement with a non-empty inline body statement
do x; while (10)
// do while statement with a non-empty block body statement
do { x; } while (10)
// do while statement with a nested do while statement
do { do x; while ("abc") } while (10)
// do while statement with a computed test
do x; while (10 + "abc" == true)
