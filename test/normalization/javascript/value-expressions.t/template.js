// simple template literal (single-line)
`abc`;
// simple template literal (multi-line)
`abc
 def`;

// template literal with an empty quasi expression
`${""}`;
// template literal with a single quasi expression
`abc${10} def`;
// template literal with multiple quasi expressions
`abc${10} def${true}`;
// template literal with a variable quasi expression
`${foo}`;

// template literal with an escaped backticks
`\`escaped backtick\``;
// template literal with escaped sequences
`abc\ndef`;
// template literal with a nested template literal
`${`abc ${10}`}`;
