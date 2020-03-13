%{
#include <stdio.h>
extern int yylex();
void yyerror(const char *msg);
extern int yylineno;
%}

/* Tokens de la gramática */

%token PROGRAM
%token FUNCTION
%token CONST
%token VAR 
%token INTTYPE 
%token BEGINN 
%token END 
%token IF 
%token THEN 
%token ELSE 
%token WHILE 
%token DO 
%token FOR 
%token TO 
%token WRITE 
%token READ 
%token ID 
%token INTCONST
%token STRING 
%token LPAREN 
%token RPAREN 
%token SEMICOLON 
%token COLON 
%token COMMA 
%token POINT 
%token ASSIGNOP 
%token PLUSOP 
%token MINUSOP 
%token MULTOP 
%token DIVOP 

%start program

/* genera trazas de depuración */
%define parse.error verbose
%define parse.trace

/* Tipos de datos */
%union {
    int num;
    char *str;
}

/* Asociatividad y preferencia */
%left PLUSOP MINUSOP
%left MULTOP DIVOP
%nonassoc THEN
%nonassoc ELSE

%%
program     : PROGRAM ID LPAREN RPAREN SEMICOLON functions declarations compound_statement POINT
            ;
functions   : functions function SEMICOLON
            |
            ;
function    : FUNCTION ID LPAREN CONST identifiers COLON type RPAREN COLON type declarations compound_statement
            ;
declarations : declarations VAR identifiers COLON type SEMICOLON
             | declarations CONST constants SEMICOLON
             |
             ;
identifiers : ID
            | identifiers COMMA ID
            ;
type        : INTTYPE
            ;
constants   : ID ASSIGNOP expression
            | constants COMMA ID ASSIGNOP expression
            ;
compound_statement : BEGINN optional_statements END
                   |
                   ;
optional_statements : statements
                    ;
statements  : statement
            | statements SEMICOLON statement
            ;
statement   : ID ASSIGNOP expression
            | IF expression THEN statement
            | IF expression THEN statement ELSE statement
            | WHILE expression DO statement
            | FOR ID ASSIGNOP expression TO expression DO statement
            | WRITE LPAREN print_list RPAREN
            | READ LPAREN read_list RPAREN
            | compound_statement
            ;
print_list  : print_item
            | print_list COMMA print_item
            ;
print_item  : expression
            | STRING
            ;
read_list   : ID
            | read_list COMMA ID
            ;
expression  : expression PLUSOP expression
            | expression MINUSOP expression
            | expression MULTOP expression
            | expression DIVOP expression
            | MINUSOP expression
            | LPAREN expression RPAREN
            | ID
            | INTCONST
            | ID LPAREN arguments RPAREN
            ;
arguments   : expressions
            |
            ;
expressions : expression
            | expressions COMMA expression
%%

void yyerror(const char *msg){
    printf("Error en linea %d: %s\n", yylineno, msg);
}
