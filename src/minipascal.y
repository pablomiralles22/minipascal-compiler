%{
    #include <stdio.h>
    #include <string.h>
    #include "listaSimbolos.h"
    #include "listaCodigo.h"
    #include "semantic_analysis.h"
    #include "code_gen.h"


    extern int yylex();
    extern int yylineno;

    int errores_sintacticos = 0;
    int errores_semanticos = 0;
    extern int errores_lexicos;
    void yyerror(const char *msg);
    int ok();

    // Lista de símbolos
    Lista l;
    // puntero auxiliar
    char* name;
%}

%code requires {
    #include "listaCodigo.h"
}

/* Tipos de datos */
%union {
    char *str;
    ListaC codigo;
}

%type <codigo> expression statement read_list print_list print_item compound_statement optional_statements statements declarations constants

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
%token <str> ID 
%token <str> INTCONST
%token <str> STRING 
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


/* Asociatividad y preferencia */
%expect 1
%left PLUSOP MINUSOP
%left MULTOP DIVOP


%%
program     : { l = creaLS(); } PROGRAM ID LPAREN RPAREN SEMICOLON functions declarations compound_statement POINT {
                if(ok()){
                    imprimirLS(l);
                    ListaC output = program_output($8, $9);
                    imprimirCodigo(output);
                    liberaLC(output);
                }
                liberaLS(l);
           }
            ;
functions   : functions function SEMICOLON
            |
            ;
function    : FUNCTION ID {
                    parse_function_declaration($2);
                } LPAREN CONST { 
                    args_on();
                } identifiers {
                    args_off();
                } COLON type RPAREN COLON type declarations compound_statement {
                    end_function_declaration();
                }
            ;
declarations : declarations VAR identifiers COLON type SEMICOLON { if(ok()) $$ = decl_id($1); }
             | declarations CONST constants SEMICOLON { if(ok()) $$ = decl_const($1, $3); }
             | { if(ok()) $$ = decl_lambda(); }
             ;
        
identifiers : ID { insert_identifier($1, VARIABLE); /* si es argumento lo detecta en el módulo*/ }
            | identifiers COMMA ID { insert_identifier($3, VARIABLE); }
            ;
type        : INTTYPE
            ;
constants   : ID ASSIGNOP expression { insert_identifier($1, CONSTANTE); if(ok()) $$ = const_assign($1, $3); }
            | constants COMMA ID ASSIGNOP expression { insert_identifier($3, CONSTANTE); if(ok()) $$ = const_claus($1, $3, $5); }
            ;
compound_statement : BEGINN optional_statements END { if(ok()) $$ = compstat_optstat($2); }
                   ;
optional_statements : statements { if(ok()) $$ = optstat_stats($1); }
                    | { if(ok()) $$ = optstat_lambda(); }
                    ;
statements  : statement { if(ok()) $$ = stats_stat($1); }
            | statements SEMICOLON statement { if(ok()) $$ = stats_claus($1, $3); }
            ;
statement   : ID ASSIGNOP expression{ 
                                        name = check_identifier($1, VARIABLE); 
                                        if(name != NULL && ok())
                                            $$ = stat_assign(name, $3);
                                    }
            | IF expression THEN statement { if(ok()) $$ = stat_if($2, $4); }
            | IF expression THEN statement ELSE statement { if(ok()) $$ = stat_if_else($2, $4, $6); }
            | WHILE expression DO statement { if(ok()) $$ = stat_while($2, $4); }
            | FOR ID ASSIGNOP expression TO expression DO statement { name = check_identifier($2, VARIABLE); if(name != NULL && ok()) $$ = stat_for(name, $4, $6, $8); }
            | WRITE LPAREN print_list RPAREN { if(ok()) $$ = stat_write($3); }
            | READ LPAREN read_list RPAREN { if(ok()) $$ = stat_read($3); }
            | compound_statement { if(ok()) $$ = stat_comp($1); }
            ;
print_list  : print_item { if(ok()) $$ = printl_printit($1); }
            | print_list COMMA print_item { if(ok()) $$ = printl_claus($1, $3); }
            ;
print_item  : expression { if(ok()) $$ = printit_exp($1); }
            | STRING {
                        int str_id = insert_string($1);
                        if(ok()) $$ = printit_str(str_id);
                    }
            ;
read_list   : ID { name = check_identifier($1, VARIABLE); if(name != NULL && ok()) $$ = readl_id(name); }
            | read_list COMMA ID { name = check_identifier($3, VARIABLE); if(name != NULL && ok()) $$ = readl_claus($1, $3);}
            ;
expression  : expression PLUSOP expression { if(ok()) $$ = expr_op($1, $3, '+'); }
            | expression MINUSOP expression { if(ok()) $$ = expr_op($1, $3, '-'); }
            | expression MULTOP expression { if(ok()) $$ = expr_op($1, $3, '*'); }
            | expression DIVOP expression { if(ok()) $$ = expr_op($1, $3, '/'); }
            | MINUSOP expression { if(ok()) $$ = expr_neg($2); }
            | LPAREN expression RPAREN { if(ok()) $$ = expr_paren($2); }
            | ID { name = check_identifier($1, VARIABLE | CONSTANTE | ARGUMENTO); if(name != NULL && ok()) $$ = expr_id($1); }
            | INTCONST { if(ok()) $$ = expr_num($1); }
            | ID { parse_function_call($1); } LPAREN arguments RPAREN { end_function_call(); if(ok()) $$ = expr_id("a"); }
            ;
arguments   : expressions
            |
            ; 
expressions : expression { add_param(); }
            | expressions COMMA expression { add_param(); }
%%

void yyerror(const char *msg){
    printf("Error en linea %d: %s\n", yylineno, msg);
    errores_sintacticos++;
}

int ok() {
    return !(errores_lexicos + errores_sintacticos + errores_semanticos);
}
