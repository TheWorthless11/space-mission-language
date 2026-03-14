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
| `launch`    | Defines a function              | Function definition     |
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

Functions are defined using the `launch` keyword.

### Syntax

```
launch TYPE function_name(parameters) start
    statements
    return value;
end
```

### Example

```
launch int add(int a, int b) start
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
launch int add(int a, int b) start
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
| Keyword             | Reserved words with predefined meaning       | `mission`, `launch`, `check`       |
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
LAUNCH
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
