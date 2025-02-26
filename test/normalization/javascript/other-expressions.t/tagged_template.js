// tagged template with no quasi expressions (single-line)
foo`abc`;
// tagged template with no quasi expressions (multi-line)
foo`abc
 def`;
// tagged template with a single quasi expression
foo`abc${10} def`;
// tagged template with multiple quasi expressions
foo`abc${10} def${true}`;
// tagged template with a computed expression
foo`abc${10 + true}`;
