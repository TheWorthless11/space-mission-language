%option yylineno
/* This makes Flex automatically count line numbers */
%{
/* -------------------------------------------------
   C CODE SECTION
   Everything inside %{ %} is copied into lex.yy.c
------------------------------------------------- */

#include <stdio.h>      // for printf
#include <stdlib.h>     // for atoi, atof if needed
#include <string.h>     // for string functions
#define MAX_ID_LENGTH 64
#include <errno.h> // strol uses this for overflow detection
//#include "parser.tab.h" // will be used later when integrating Bison
int column = 1;   /* tracks column number */
int token_column = 1; /* column where current token starts */
#define YY_USER_ACTION \
    token_column = column; \
    column += yyleng; /* update column based on length of matched text */

#define MAX_STRING_LENGTH 1024

char string_buffer[MAX_STRING_LENGTH];
int str_index = 0;

%}



/* -------------------------------------------------DEFINITIONS SECTION. Reusable regular expressions------------------------------------------------- */
%x STRING
/* digits 0-9 */
DIGIT      [0-9]

/* alphabet letters */
LETTER     [a-zA-Z]

/* ------------------------------------------------- IDENTIFIER RULE . Must start with a letter. After that letters, digits or underscore allowed------------------------------------------------- */
IDENTIFIER [a-zA-Z][a-zA-Z0-9_]*

/* -------------------------------------------------NUMERIC LITERALS------------------------------------------------- */

/* integer numbers like 10, 500, 123 */
INTEGER    {DIGIT}+

/* floating numbers like 3.14, 7.5 dot must be escaped with \. */
FLOATNUM   {DIGIT}+\.{DIGIT}+


/* -------------------------------------------------WHITESPACE. space, tab,------------------------------------------------- */
WHITESPACE [ \t\r]+

/* RULES SECTION. pattern  -> action*/
%%


"mission"      { printf("TOKEN: MISSION\n"); } /* KEYWORDS */
"module"       { printf("TOKEN: MODULE\n"); }

"check"        { printf("TOKEN: CHECK\n"); }
"otherwise"    { printf("TOKEN: OTHERWISE\n"); }

"orbit"        { printf("TOKEN: ORBIT\n"); }

"transmit"     { printf("TOKEN: TRANSMIT\n"); }

"return"       { printf("TOKEN: RETURN\n"); }

"start"        { printf("TOKEN: START\n"); }
"end"          { printf("TOKEN: END\n"); }




"int"          { printf("TOKEN: INT\n"); } /* ---------------- DATA TYPES ---------------- */
"float"        { printf("TOKEN: FLOAT\n"); }
"string"       { printf("TOKEN: STRING\n"); }
"flag"         { printf("TOKEN: FLAG\n"); }




"=="           { printf("TOKEN: EQUAL\n"); } /* ---------------- OPERATORS ---------------- */
"!="           { printf("TOKEN: NOT_EQUAL\n"); }

"<="           { printf("TOKEN: LESS_EQUAL\n"); }
">="           { printf("TOKEN: GREATER_EQUAL\n"); }

"&&" { printf("TOKEN: AND\n"); }
"||" { printf("TOKEN: OR\n"); }
"!"  { printf("TOKEN: NOT\n"); }

"="            { printf("TOKEN: ASSIGN\n"); }

"+"            { printf("TOKEN: PLUS\n"); }
"-"            { printf("TOKEN: MINUS\n"); }

"*"            { printf("TOKEN: MULTIPLY\n"); }
"/"            { printf("TOKEN: DIVIDE\n"); }

">"            { printf("TOKEN: GREATER\n"); }
"<"            { printf("TOKEN: LESS\n"); }




"("            { printf("TOKEN: LPAREN\n"); } /* ---------------- DELIMITERS ---------------- */
")"            { printf("TOKEN: RPAREN\n"); }
"[" { printf("TOKEN: LBRACKET\n"); }
"]" { printf("TOKEN: RBRACKET\n"); }

"{" { printf("TOKEN: LBRACE\n"); }
"}" { printf("TOKEN: RBRACE\n"); }


";"            { printf("TOKEN: SEMICOLON\n"); }
","            { printf("TOKEN: COMMA\n"); }

"true"  { printf("TOKEN: TRUE\n"); }
"false" { printf("TOKEN: FALSE\n"); }

"//"[^\n]*     ; /* ---------------- IGNORE SINGLE-LINE COMMENTS ---------------- */

"/*" {
   char c;
   int start_line = yylineno; 

   while((c=input())!= 0){
      if(c=='\n')
      {
         column=1;

      }
      

      if((c =='*') )
      {
         if((c=input())=='/') /*input read next character*/
         break;
         else
         unput(c); /*push character back*/
      }
   }

    /* If we reach here → EOF before closing comment */
    if(c == 0)
{
    printf("LEXICAL ERROR: Unclosed comment starting at line %d column %d\n", start_line, token_column);
}
}

{DIGIT}+\. {
    printf("LEXICAL ERROR at line %d column %d: malformed float '%s'\n", yylineno, token_column, yytext);
}

\.{DIGIT}+ {
    printf("LEXICAL ERROR at line %d column %d: malformed float '%s'\n", yylineno, token_column, yytext);
}

{FLOATNUM}     { printf("TOKEN: FLOAT_LITERAL (%s)\n", yytext); } /* ---------------- NUMERIC LITERALS  float numbers */



{INTEGER}      {errno = 0; /*reset errno*/
long val = strtol(yytext, NULL, 10);

if(errno == ERANGE) /*value out of range (overflow or underflow)*/
    printf("LEXICAL ERROR: integer overflow at line %d column %d\n", yylineno, token_column);
else
    printf("TOKEN: INTEGER_LITERAL (%ld)\n", val);} /* integers */






\" { str_index = 0;
    string_buffer[0] = '\0'; 
   BEGIN(STRING); }  /* When the lexer sees a double quote ", it means a string is starting.
                       BEGIN(STRING) switches the lexer to the STRING state so that
                       special rules for string processing become active. */

<STRING>\" {
    BEGIN(INITIAL);
    printf("TOKEN: STRING_LITERAL (%s)\n", string_buffer);
}                       /* If the lexer is in STRING state and sees another double quote ",
                        this means the string has ended.
                        BEGIN(INITIAL) switches the lexer back to the normal scanning state.
                        Then we print that a STRING_LITERAL token was recognized. */

<STRING>[^\\\"\n]+ {
   if(str_index + yyleng >= MAX_STRING_LENGTH){
        printf("LEXICAL ERROR: string too long at line %d column %d\n", yylineno, column);
    } else {
        memcpy(&string_buffer[str_index], yytext, yyleng); /*memcpy(destination, source, number_of_bytes);*/
        str_index += yyleng;
        string_buffer[str_index] = '\0';
    }
}    /* While inside a string, this rule matches one or more normal characters.
                        It allows any character except:
                        \\  -> backslash (because it may start an escape sequence)
                        \"  -> double quote (because it may end the string)
                        \n  -> newline (because strings cannot span multiple lines)
                        These characters are simply ignored since they are valid string content. */

<STRING>\\[ntr\"\\] {
   char c;

    switch(yytext[1]) {
        case 'n': c = '\n'; break;
        case 't': c = '\t'; break;
        case 'r': c = '\r'; break;
        case '"': c = '"'; break;
        case '\\': c = '\\'; break;
    }

    if(str_index + 1 >= MAX_STRING_LENGTH){
        printf("LEXICAL ERROR: string too long at line %d column %d\n", yylineno, token_column);
    } else {
        string_buffer[str_index++] = c;
        string_buffer[str_index] = '\0'; /*every string must end with:'\0'*/
    }
}   /* This rule matches valid escape sequences inside the string.
   The pattern means:
      \\  -> a backslash
      followed by one of:
         n  -> newline escape (\n)
         t  -> tab escape (\t)
         r  -> carriage return (\r)
         \" -> escaped double quote
         \\ -> escaped backslash
   These sequences are valid, so we just accept them and continue. */

<STRING>\\[^ntr\"\\] {
    printf("LEXICAL ERROR at line %d column %d: Invalid escape sequence %s\n",yylineno, token_column, yytext);
}  /* This rule catches invalid escape sequences.
   It matches a backslash followed by a character that is NOT one of:
      n, t, r, ", \
   Example invalid escapes:
      \q
      \a
      \z
   When detected, we report a lexical error with the line number. */

<STRING>\n {
    printf("LEXICAL ERROR at line %d column %d: Unterminated string literal\n",yylineno, token_column);
    BEGIN(INITIAL);
}/* If a newline is encountered before the closing quote,
   it means the string was never properly terminated.
   We report an error and return to the INITIAL state
   so the lexer can continue scanning the rest of the file. */

<STRING><<EOF>> {
    printf("LEXICAL ERROR at line %d column %d: Unterminated string before EOF\n",yylineno, token_column);
    BEGIN(INITIAL);
}/* If the file ends while still inside a string (EOF encountered),
   the string was never closed.
   This rule reports the error when the end-of-file occurs. */

{IDENTIFIER} {
    if(strlen(yytext) > MAX_ID_LENGTH)
        printf("LEXICAL ERROR at line %d column %d: identifier too long '%s'\n", yylineno, token_column, yytext);
    else
        printf("TOKEN: IDENTIFIER (%s)\n", yytext);
} /* ---------------- IDENTIFIERS ---------------- */

\n { column = 1; } 

{WHITESPACE} ;   /*  skip spaces, tabs. yyleng-> length of the matched text */ /* ---------------- IGNORE WHITESPACE ---------------- */




[^a-zA-Z0-9_ \t\r\n;,+\-*/<>=(){}\[\]!|"]+ { /* ---------------- ERROR HANDLING ---------------- */
     printf("LEXICAL ERROR at line %d column %d: Invalid token '%s'\n",yylineno, token_column, yytext); /* any unknown character gives error with line number*/
}


%%


/* -------------------------------------------------
   Called when lexer reaches end of file
------------------------------------------------- */
int yywrap()
{
    return 1;
}


/* -------------------------------------------------
   Main function
   Starts the lexical analyzer
------------------------------------------------- */
int main()
{
    printf("Space Mission Language Lexer Started...\n\n");
    yylex();   /* start scanning input */
    return 0;
}

/*

| Return Value | Meaning                        |
| ------------ | ------------------------------ |
| `return 1`   | No more files → stop lexer     |
| `return 0`   | More input → continue scanning |


*/