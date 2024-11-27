// object expression with a method field
({ foo() { } });
// object expression with a literal key method field
({ 10() { } });
// object expression with a computed key method field
({ [foo]() { } });
// object expression with a getter field
({ get foo() { } });
// object expression with a literal key getter field
({ get 10() { } });
// object expression with a computed key getter field
({ get [foo]() { } });
// object expression with a setter field
({ set foo(bar) { } });
// object expression with a literal key setter field
({ set 10(bar) { } });
// object expression with a computed key setter field
({ set [foo](bar) { } });
// object expression with a getter and setter fields
({ get foo() { }, set foo(bar) { } });
