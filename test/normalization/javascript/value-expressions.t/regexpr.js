// regexpr for empty strings
/^$/;
// regexpr for identifiers
/^[a-zA-Z_$][a-zA-Z0-9_$]*$/;
// regexpr for number literals
/^(0[xX][0-9a-fA-F]+|0[bB][01]+|0[oO][0-7]+|\d+(\.\d+)?([eE][+-]?\d+)?|\.\d+([eE][+-]?\d+)?)$/;
// regexpr for string literals
/(['"])(?:(?=(\\?))\2.)*?\1/;
// regexpr for comments (single-line and multi-line)
/(\/\/[^\n]*|\/\*[\s\S]*?\*\/)/;
// regexpr for whitespace
/\s+/;
// regexpr for braces, brackets, and parentheses
/[\(\)\[\]\{\}]/;
// global regexpr for digits
/\d+/g;

// regexpr with a backslash escape sequence
/\\/g;
// regexpr with two digit match
/\d{2}/;
// regexpr with word character match
/\w+/;

// regexpr with start boundary
/^abc/;
// regexpr with end boundary
/abc$/;
// regexpr with word boundary
/\bword\b/;


// regexpr with optional capturing groups
/(?:abc|def)/;
// regexpr with named capturing group
/(?<digit>\d+)/;

// regexpr with positive lookahead
/(?=\d)/;
// regexpr with negative lookahead
/(?!\d)/;
