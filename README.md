# Space Mission Language (SML)

Space Mission Language (SML) is a small domain-specific programming language inspired by **space mission control commands**.
It is designed as an educational project to demonstrate the core phases of compiler construction using **Flex** (lexical analysis) and **Bison** (syntax analysis).


---

# Implementation

The compiler for **Space Mission Language** is implemented using:

* **Flex** — lexical analysis
* **Bison** — syntax analysis
* **C** — runtime and code generation

---

# Keyword Reference

The following table lists the core keywords used in **Space Mission Language (SML)** and their meanings.

| Keyword     | Purpose                         | Equivalent Concept in C |
| ----------- | ------------------------------- | ----------------------- |
| `mission`   | Declares the main program       | `int main()`            |
| `module`    | Defines a function              | Function definition     |
| `start`     | Begins a code block             | `{`                     |
| `end`       | Ends a code block               | `}`                     |
| `check`     | Conditional statement           | `if`                    |
| `otherwise` | Alternative condition           | `else`                  |
| `orbit`     | Loop statement                  | `while`                 |
| `transmit`  | Output statement                | `printf()`              |
| `return`    | Returns a value from a function | `return`                |

---

# Operators

| Operator | Meaning                 | Equivalent in C |
| -------- | ----------------------- | --------------- |
| `=`      | Assignment              | `=`             |
| `+`      | Addition                | `+`             |
| `-`      | Subtraction             | `-`             |
| `*`      | Multiplication          | `*`             |
| `/`      | Division                | `/`             |
| `>`      | Greater than comparison | `>`             |
| `<`      | Less than comparison    | `<`             |
| `==`     | Equality comparison     | `==`            |

---

# Data Types

| Type     | Description     | Example                 |
| -------- | --------------- | ----------------------- |
| `int`    | Integer values  | `int fuel = 100;`       |
| `float`  | Decimal numbers | `float speed = 7.5;`    |
| `string` | Text values     | `string msg = "Hello";` |
| `flag`   | Boolean values  | `flag ready = true;`    |

Example:

```
int fuel = 100;
float velocity = 7.8;
string message = "Launch Ready";
```

---

# Program Structure

Every program begins with a **mission declaration**.

### Syntax

```
mission IDENTIFIER start
    statements
end
```

### Example

```
mission Apollo start
    int fuel = 100;
    transmit fuel;
end
```

### Equivalent C

```c
#include <stdio.h>

int main() {
    int fuel = 100;
    printf("%d", fuel);
}
```

---

# Variable Naming Rules

Identifiers (variable and function names) must follow these rules in **Space Mission Language (SML)**.

| Rule                 | Description                                                                          |
| -------------------- | ------------------------------------------------------------------------------------ |
| Start with letter    | Variable names must begin with a letter (`a–z` or `A–Z`)                             |
| Use meaningful words | Names should represent meaningful concepts (e.g., `fuel`, `orbitSpeed`, `starCount`) |
| Digits allowed       | Numbers may be used **after the first character**                                    |
| Underscore allowed   | `_` may be used to separate words                                                    |
| No special symbols   | Characters like `@`, `#`, `$`, `%`, `!` are **not allowed**                          |
| Case sensitive       | `star` and `Star` are treated as **different identifiers**                           |

---

### Examples

Valid identifiers:

```
fuel
starCount
orbit_speed
distance1
MarsMission
```

Invalid identifiers:

```
1fuel      (cannot start with a number)
fuel@tank  (special characters not allowed)
orbit-speed (hyphen not allowed)
```

---

### Identifier Pattern

In the compiler implementation, identifiers follow this pattern:

```
[a-zA-Z][a-zA-Z0-9_]*
```

This rule will be used in the **Flex lexer** to recognize variable and function names.

---

# Variable Declaration and Assignment

Variables can be declared using a data type and assigned a value using the assignment operator `=`.

### Example

```
int fuel = 100;
fuel = fuel - 10;
```

### Equivalent C

```c
int fuel = 100;
fuel = fuel - 10;
```

This allows variables to store values and update them during program execution.

---

# Functions

Functions are defined using the `module` keyword.

### Syntax

```
module TYPE function_name(parameters) start
    statements
    return value;
end
```

### Example

```
module int add(int a, int b) start
    return a + b;
end
```

### Equivalent C

```c
int add(int a, int b) {
    return a + b;
}
```

---

# Conditional Statements

Conditional execution is performed using `check` and `otherwise`.

### Syntax

```
check (condition) start
    statements
end
otherwise start
    statements
end
```

### Example

```
check (fuel > 50) start
    transmit "Launch Ready";
end
otherwise start
    transmit "Low Fuel";
end
```

---

# Loops

Loops are implemented using the `orbit` keyword.

### Syntax

```
orbit (condition) start
    statements
end
```

### Example

```
orbit (fuel > 0) start
    fuel = fuel - 10;
end
```

### Equivalent C

```c
while (fuel > 0) {
    fuel = fuel - 10;
}
```

---

# Output

Output is performed using the `transmit` command.

### Syntax

```
transmit expression;
```

### Example

```
transmit "Launch Ready";
transmit fuel;
```

Equivalent C:

```c
printf("Launch Ready");
printf("%d", fuel);
```

---

# Complete Example Program

```
module int add(int a, int b) start
    return a + b;
end

mission Apollo start

    int fuel = 100;

    check (fuel > 50) start
        transmit "Launch Ready";
    end
    otherwise start
        transmit "Low Fuel";
    end

    int result = add(5,3);
    transmit result;

end
```

---

# Lexical Tokens

During lexical analysis, the compiler breaks the source code into **tokens**.
The following categories define the tokens recognized by **Space Mission Language (SML)**.

| Token Type          | Description                                  | Example                            |
| ------------------- | -------------------------------------------- | ---------------------------------- |
| Keyword             | Reserved words with predefined meaning       | `mission`, `module`, `check`       |
| Identifier          | Names of variables and functions             | `fuel`, `orbitSpeed`, `starCount`  |
| Number              | Numeric values                               | `10`, `100`, `3.14`                |
| String Literal      | Text enclosed in quotes                      | `"Launch Ready"`                   |
| Operator            | Mathematical and comparison operators        | `+`, `-`, `*`, `/`, `>`, `<`, `==` |
| Assignment Operator | Assigns a value to a variable                | `=`                                |
| Delimiter           | Symbols that structure statements            | `(` `)` `;`                        |
| Block Keywords      | Control the beginning and end of code blocks | `start`, `end`                     |

---

### Example Tokenization

Source code:

```
int fuel = 100;
check (fuel > 50) start
    transmit "Launch Ready";
end
```

Token sequence:

```
INT IDENTIFIER ASSIGN NUMBER SEMICOLON
CHECK LPAREN IDENTIFIER GREATER NUMBER RPAREN START
TRANSMIT STRING_LITERAL SEMICOLON
END
```

---

### Token Categories Used by the Lexer

The Flex lexer will typically define tokens such as:

```
MISSION
MODULE
CHECK
OTHERWISE
ORBIT
TRANSMIT
RETURN

INT
FLOAT
STRING
FLAG

IDENTIFIER
NUMBER
STRING_LITERAL

PLUS
MINUS
MULTIPLY
DIVIDE
GREATER
LESS
EQUAL
ASSIGN
```

These tokens are then passed to the **Bison parser** to build the program structure.

---

# Error Handling

The compiler detects and reports errors during different phases of compilation.

---

## Lexical Error Handling

During lexical analysis, the **Flex lexer** identifies invalid characters or tokens that do not match the language rules.

If an invalid symbol appears in the source code, the compiler reports a **lexical error**.

### Example

Invalid code:

```
@fuel = 100;
```

Output:

```
Lexical Error: Invalid token '@'
```

This ensures that only valid identifiers, numbers, operators, and keywords are processed by the parser.

---

## Syntax Error Handling

During syntax analysis, the **Bison parser** checks whether the program follows the grammar rules of Space Mission Language.

If the structure of the program is incorrect, the compiler reports a **syntax error**.

### Example

Invalid code:

```
check (fuel > 50)
    transmit "Launch Ready";
end
```

Error:

```
Syntax Error: expected 'start' after condition
```

The parser helps ensure that program blocks and statements follow the correct syntax.

---

# Compiler Workflow

The **Space Mission Language compiler** processes programs through several stages.

```
Space Mission Language Source Code
            │
            ▼
      Lexical Analysis
        (Flex Lexer)
            │
            ▼
           Tokens
            │
            ▼
      Syntax Analysis
        (Bison Parser)
            │
            ▼
         Parse Tree
            │
            ▼
      Semantic Analysis
 (Type checking, declarations,
  expression validation)
            │
            ▼
   Intermediate Representation
      (Optional Feature)
            │
            ▼
      Program Execution
            │
            ▼
         Program Output
```

### Stage Description

| Stage             | Description                                         |
| ----------------- | --------------------------------------------------- |
| Lexical Analysis  | Converts source code into tokens using Flex         |
| Syntax Analysis   | Checks grammar rules using Bison                    |
| Parse Tree        | Structural representation of program                |
| Semantic Analysis | Validates variable declarations, types, expressions |
| Intermediate Code | Optional stage for code generation                  |
| Execution         | Program behavior is executed or interpreted         |
| Output            | Final program result                                |

---

# Flex Lexer Implementation Details

The **Space Mission Language (SML) lexer** is implemented using **Flex** and performs lexical analysis by scanning the source code and converting it into a sequence of tokens.
These tokens are later passed to the **Bison parser** for syntax analysis.

---

## Token Recognition

The lexer identifies the following token categories:

* Keywords (`mission`, `module`, `check`, `orbit`, `transmit`, etc.)
* Identifiers
* Integer literals
* Floating-point literals
* String literals
* Operators
* Delimiters
* Boolean literals (`true`, `false`)

Each token is printed in the following format:

```
TOKEN: TOKEN_NAME (value)
```

Example:

```
TOKEN: IDENTIFIER (fuel)
TOKEN: INTEGER_LITERAL (100)
TOKEN: STRING_LITERAL (Launch Ready)
```

---

## Supported String Features

The lexer supports **string literals with escape sequences**.

Example:

```
"Hello World"
"Line1\nLine2"
"Tab\tSeparated"
"Quote: \"Hello\""
"Backslash: \\"
```

Supported escape sequences:

| Escape | Meaning         |
| ------ | --------------- |
| `\n`   | newline         |
| `\t`   | tab             |
| `\r`   | carriage return |
| `\"`   | double quote    |
| `\\`   | backslash       |

Invalid escape sequences are detected and reported as lexical errors.

---

## Numeric Literal Handling

The lexer supports both **integer** and **floating-point** numbers.

Examples:

```
10
150
3.14
7.8
```

The lexer also detects malformed numeric literals such as:

```
5.
.5
```

These are reported as **malformed floating-point errors**.

---

## Integer Overflow Detection

Integer values are parsed using `strtol()` and checked for overflow using `errno`.

Example:

```
999999999999999999999999999999
```

Output:

```
LEXICAL ERROR: integer overflow
```

---

## Comment Handling

The lexer supports two types of comments.

### Single-line comment

```
// This is a comment
```

### Multi-line comment

```
/*
This is a multi-line comment
spanning multiple lines
*/
```

Comments are ignored by the lexer during tokenization.

---

## Error Reporting with Line and Column Numbers

All lexical errors include **precise location information**.

Example:

```
LEXICAL ERROR at line 85 column 13: Invalid token '$'
```

This helps developers quickly locate errors in the source code.

---

## Additional Error Detection

The lexer detects several lexical errors including:

* Invalid tokens (e.g., `$`, `@`)
* Invalid escape sequences
* Unterminated string literals
* Unclosed multi-line comments
* Integer overflow
* Malformed floating-point numbers
* Identifiers exceeding maximum length

---

## Example Lexer Output

Input program:

```
int fuel = 100;
transmit "Launch Ready";
```

Lexer output:

```
TOKEN: INT
TOKEN: IDENTIFIER (fuel)
TOKEN: ASSIGN
TOKEN: INTEGER_LITERAL (100)
TOKEN: SEMICOLON
TOKEN: TRANSMIT
TOKEN: STRING_LITERAL (Launch Ready)
TOKEN: SEMICOLON
```

---

# Bison Parser Implementation Details

The **Space Mission Language (SML) parser** is implemented using **Bison** and performs syntax + semantic analysis over the token stream produced by Flex.

The parser validates:

* Program structure (`mission ... start ... end`)
* Declarations, assignments, and expressions
* Conditional and loop blocks
* Function declarations and function calls
* Type compatibility in expressions and assignments

---

## Grammar Coverage

The parser handles these core grammar components:

* Program (`functions` + `mission` block)
* Statements (`declaration`, `assignment`, `print`, `if`, `loop`, `return`)
* Blocks (`start ... end`) with nested scopes
* Expressions with arithmetic, relational, and logical operators
* Function definitions with parameter lists
* Function calls with argument lists

---

## Operator Precedence and Associativity

The parser uses precedence rules to correctly parse complex expressions.

From lowest to highest precedence:

1. `OR`
2. `AND`
3. `EQUAL`, `NOT_EQUAL`
4. `LESS`, `GREATER`, `LESS_EQUAL`, `GREATER_EQUAL`
5. `PLUS`, `MINUS`
6. `MULTIPLY`, `DIVIDE`
7. Unary `NOT`

This ensures expressions like:

```
a = add(5) + sum(2, 3) * 2;
```

are parsed with the expected order.

---

## Symbol Table and Scope Handling

Semantic analysis is integrated with parsing using a scope-aware symbol table.

It supports:

* Entering/exiting scopes for mission block, function block, and nested blocks
* Variable declaration checks (same-scope redeclaration detection)
* Variable lookup from inner scope to outer scope
* Type retrieval for assignment and expression validation

---

## Function Handling

The parser stores function signatures as:

* Function name
* Declared return type (from `module TYPE name(...)`)
* Ordered parameter type list

During function parsing, the compiler also tracks inferred return type from `return` statements and validates it against the declared return type.

During function calls, it validates:

* Function existence
* Argument count (arity)
* Argument type compatibility

This enables overload-like matching by parameter signature.

---

## Type Checking Rules

The parser performs semantic checks such as:

* Assignment type match (`int = int`, `string = string`, etc.)
* Implicit numeric assignment conversion (`int -> float` allowed, `float -> int` rejected)
* Logical operator type checks (`AND`, `OR`, `NOT` require `flag`)
* Arithmetic operator compatibility (`+`, `-`, `*`, `/` require numeric operands)
* Numeric result promotion (`int/float` mixed arithmetic produces `float`)
* Relational comparison compatibility (`<`, `>`, `==`, etc.)
* Condition checks for control flow (`check(...)` and `orbit(...)` require `flag`)
* Function return-type consistency inside a function body

Type errors are reported without immediately terminating parsing where recovery is possible.

---

## Parser Error Recovery

The parser includes Bison error-recovery rules for statements:

* `error SEMICOLON`

This allows the parser to skip malformed statements and continue parsing later input instead of stopping at the first syntax error.

---

## Example Parser Diagnostics

Typical parser/semantic diagnostics include:

```
Syntax Error at line 11: syntax error
Error: Variable 'x' not declared
Type Error: cannot assign string to int
Error: function 'sum' called with wrong number of arguments
Error: function 'greet' called with wrong argument types
Type Error: condition must be flag
Type Error: function return type mismatch
```

---

## Conflict and Grammar Improvements

The parser grammar was improved to eliminate heavy Bison conflicts and increase stability.

Key improvements include:

* Refactored statement-list handling (`statements_opt` + non-empty `statements`)
* Simplified `if/else` design using `if_stmt` + `if_tail`
* Reusable `block` nonterminal with correct scope enter/exit
* Better semantic value lifetime handling in function rules

These changes removed prior shift/reduce and reduce/reduce conflict issues and made parser behavior more predictable.

---

# AST (Abstract Syntax Tree)

The parser now builds a simple AST while preserving semantic checks.

Implemented node families include:

* Expressions: literals, identifiers, unary, binary, function calls
* Statements: declaration, assignment, print, return, if, loop
* Program root: `ProgramAST`

The AST can be printed in a readable tree format (shown in debug mode).

---

# IR (Intermediate Representation)

The compiler generates a simple 3-address-style IR from the AST.

IR characteristics:

* Temporary-based expressions (`t1`, `t2`, ...)
* Label-based control flow (`L1`, `L2`, ...)
* Assignment, print, return, conditional jump, loop jump instructions
* Function-call IR emission (`call f(...)`)

Built-in IR expansion:

* `ignite(x)` expands to:
    * `t1 = x * 2`
    * `t2 = t1 + 10`

IR is printed in both normal and debug modes.

---

# Runtime Modes (Normal vs Debug)

The parser executable supports two runtime modes:

* **Normal mode**
    * Shows essential diagnostics and IR output
    * Keeps output clean for regular usage

* **Debug mode**
    * Enabled automatically when compiled with `-DDEBUG`
    * Prints semantic action traces (declarations, assignments, expression evaluation, function events)
    * Prints lexer tokens
    * Prints symbol table and AST
    * Also prints IR output

Optional runtime override:

* `nodebug` disables both lexer and parser debug output even in a `-DDEBUG` build.

Example usage:

```bash
# Debug OFF (normal build)
g++ lex.yy.c parser.tab.c -o sml
./sml test_all.sml

# Debug ON (compile-time)
g++ -DDEBUG lex.yy.c parser.tab.c -o sml
./sml test_all.sml

# Debug build, but force OFF at runtime
./sml nodebug test_all.sml
```

---

# Test Files

The project includes focused, feature-based tests and one comprehensive test file.

Focused tests:

* `test_declaration.sml` — declarations for `int`, `float`, `string`, `flag`
* `test_assignment.sml` — valid and invalid assignments
* `test_expression.sml` — arithmetic and mixed-precedence expressions
* `test_condition.sml` — valid/invalid `check` conditions
* `test_loop.sml` — `orbit` loop with valid flag condition
* `test_function.sml` — function return validation
* `test_function_call.sml` — valid call + wrong arity/type cases
* `test_builtin_ignite.sml` — `ignite(x)` usage
* `test_error.sml` — undeclared variable, redeclaration, type mismatch

Comprehensive test:

* `test_all.sml` — declarations, assignments, expressions, control flow, function definition/call, and `ignite()` usage in one program

---

# Educational Purpose

This project demonstrates key compiler concepts including:

* Tokenization (lexical analysis)
* Grammar parsing
* Syntax trees
* Expression evaluation
* Control flow implementation

---

# Author

Mahhia  
CSE Undergraduate Student

Developed as part of a **Compiler Design Lab course project**.
