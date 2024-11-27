// class expression with an uninitialized property
(class { foo; });
// class expression with an uninitialized literal key property
(class { 10; });
// class expression with an uninitialized computed key property
(class { [foo]; });
// class expression with an uninitialized static property
(class { static foo; });
// class expression with an initialized property
(class { foo = 10; });
// class expression with an initialized literal key property
(class { 10 = 10; });
// class expression with an initialized computed key property
(class { [foo] = 10; });
// class expression with an initialized static property
(class { static foo = 10; });
