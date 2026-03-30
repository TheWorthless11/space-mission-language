# Expected Errors Checklist: test_comprehensive_errors.sml

Use this checklist to verify that each intentional error case in
`test_comprehensive_errors.sml` is reported by the compiler.

Notes:
- Match by key message text (substring), not exact output order.
- Multiple errors may be reported in one run.

| Line | Error Case | Expected Message (substring) |
| --- | --- | --- |
| 8 | function with missing return | `Type Error: function 'noReturn' has no return statement` |
| 14 | function with inconsistent return types | `Type Error: inconsistent return types in function` |
| 32 | use of undeclared variable | `Error: Variable 'unknownValue' not declared` |
| 35 | redeclaration in same scope | `Error: Variable 'x' already declared in this scope` |
| 38 | assigning wrong type (int = string) | `Type Error: cannot assign string to int` |
| 41 | invalid operation (number + string) | `Type Error: incompatible types for +` |
| 44 | invalid condition type in check | `Type Error: condition must be flag` |
| 49 | invalid condition type in orbit | `Type Error: condition must be flag` |
| 54 | calling undeclared function | `Error: function 'ghost' is not declared` |
| 57 | wrong number of args (user function) | `Error: function 'addTwo' called with wrong number of arguments` |
| 60 | wrong argument types (user function) | `Error: function 'addTwo' called with wrong argument types` |
| 63 | percent division by zero | `Error: function 'percent' division by zero` |
| 66 | ignite wrong argument count | `Error: function 'ignite' called with wrong number of arguments` |
| 69 | ignite wrong argument type | `Error: function 'ignite' expects int or float argument` |
| 72 | percent wrong argument count | `Error: function 'percent' called with wrong number of arguments` |
| 75 | percent wrong argument type | `Error: function 'percent' expects int or float arguments` |
| 78 | variable out of scope | `Error: Variable 'localOnly' not declared` |
| 86 | invalid logical operation (int AND int) | `Type Error: logical AND needs flag` |
| 89 | invalid unary operation (NOT on int) | `Type Error: logical NOT needs flag` |
| 92 | invalid unary operation (minus on string) | `Type Error: unary minus needs int or float` |
