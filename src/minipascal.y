%{
    #include <stdio.h>
    #include <string.h>
    #include "listaSimbolos.h"
    #include "listaCodigo.h"
    #include "code_gen.h"
    #define BUFFSIZE 1024
    // Para errores
    #define REDECLARATION 0
    #define NOTDECLARED 1
    #define WRONGTYPE 2
    #define FUNCARGNAME 3
    #define NOTAFUNCTION 4

    char* errores[] = {
        "redeclarado", 
        "no declarado", 
        "no es del tipo adecuado", 
        "es el nombre de la función",
        "no es una función"
    };
    void throw_semantic_error(char*, int);

    extern int yylex();
    extern int yylineno;

    int errores_sintacticos = 0;
    int errores_semanticos = 0;
    extern int errores_lexicos;
    int args_on = 0;
    int count_args;
    int contador_cadenas = 1;
    void yyerror(const char *msg);
    int ok();

    // Lista de símbolos
    Lista l;
    
    // Funcion actual
    PosicionLista current_function = NULL;

    // Buffer para guardar nombre del ID
    char buffer[BUFFSIZE];
    char* name;

    // Generar .data
    void imprimirLS();

    // Función para insertar un ID en la lista
    void insert_id(char*, int);
    void get_id(char*, int);
    PosicionLista get_function(char*);

%}

%code requires {
    #include "listaCodigo.h"
}

/* Tipos de datos */
%union {
    char *str;
    ListaC codigo;
}

%type <codigo> expression

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
program     : { l = creaLS(); } PROGRAM ID LPAREN RPAREN SEMICOLON functions declarations compound_statement POINT { imprimirLS(); liberaLS(l); }
            ;
functions   : functions function SEMICOLON
            |
            ;
function    : FUNCTION ID {
                    insert_id($2, FUNCION);
                    current_function = finalLS(l);
                } LPAREN CONST { 
                    args_on = 1; 
                } identifiers {
                    args_on = 0;
                    if(current_function->dato.valor > 4){
                        errores_semanticos++;
                        printf("Error en la función %s, más de 4 argumentos\n", $2);
                    }
                } COLON type RPAREN COLON type declarations compound_statement {
                    current_function = NULL;
                }
            ;
declarations : declarations VAR identifiers COLON type SEMICOLON
             | declarations CONST constants SEMICOLON
             |
             ;
        
identifiers : ID {
                     if(args_on) insert_id($1, ARGUMENTO),current_function->dato.valor++; 
                     else insert_id($1, VARIABLE);
                 }
            | identifiers COMMA ID {
                                         if(args_on) insert_id($3, ARGUMENTO),current_function->dato.valor++; 
                                         else insert_id($3, VARIABLE);
                                   }
            ;
type        : INTTYPE
            ;
constants   : ID ASSIGNOP expression {insert_id($1, CONSTANTE);}
            | constants COMMA ID ASSIGNOP expression {insert_id($3, CONSTANTE);}
            ;
compound_statement : BEGINN optional_statements END
                   |
                   ;
optional_statements : statements
                    ;
statements  : statement
            | statements SEMICOLON statement
            ;
statement   : ID ASSIGNOP expression{ 
                                        imprimirCodigo($3);
                                        if(current_function == NULL || strcmp(current_function->dato.nombre, $1) != 0)
                                            // si no estamos haciendo un return o no estamos en una función
                                            get_id($1, VARIABLE); 
                                    }
            | IF expression THEN statement
            | IF expression THEN statement ELSE statement
            | WHILE expression DO statement
            | FOR ID ASSIGNOP expression TO expression DO statement { get_id($2, VARIABLE); }
            | WRITE LPAREN print_list RPAREN
            | READ LPAREN read_list RPAREN
            | compound_statement
            ;
print_list  : print_item
            | print_list COMMA print_item
            ;
print_item  : expression {imprimirCodigo($1);}
            | STRING {
                        PosicionLista p = buscaLS(l, $1);
                        if(p == finalLS(l) || recuperaLS(l, p).tipo != CADENA){
                            Simbolo aux;
                            aux.nombre = strdup($1);
                            aux.tipo = CADENA;
                            aux.valor = contador_cadenas++;
                            insertaLS(l, finalLS(l), aux);
                        } 
                    }
            ;
read_list   : ID { get_id($1, VARIABLE); }
            | read_list COMMA ID { get_id($3, VARIABLE);}
            ;
expression  : expression PLUSOP expression { $$ = expr_op($1, $3, '+'); }
            | expression MINUSOP expression { $$ = expr_op($1, $3, '-'); }
            | expression MULTOP expression { $$ = expr_op($1, $3, '*'); }
            | expression DIVOP expression { $$ = expr_op($1, $3, '/'); }
            | MINUSOP expression { $$ = expr_neg($2); }
            | LPAREN expression RPAREN { $$ = expr_paren($2); }
            | ID { get_id($1, VARIABLE | CONSTANTE | ARGUMENTO); $$ = expr_id($1); }
            | INTCONST { $$ = expr_num($1); }
            | ID { current_function = get_function($1); } LPAREN arguments RPAREN {
                                                                        if(current_function != NULL && current_function->dato.valor != count_args)
                                                                            printf("Error en la línea %d: %s número incorrecto de argumentos\n", yylineno, current_function->dato.nombre);
                                                                        current_function = NULL;
                                                                        $$ = creaLC();
                                                                  }
            ;
arguments   : { count_args = 1; } expressions
            |
            ; expressions : expression
            | expressions COMMA expression { count_args++; }
%%

void yyerror(const char *msg){
    printf("Error en linea %d: %s\n", yylineno, msg);
    errores_sintacticos++;
}

void insert_id(char* arg, int type){
    // If in function
    if(current_function != NULL){
        // Check if the id is the same as the function ID
        if(strcmp(arg, current_function->dato.nombre) == 0){
            throw_semantic_error(arg, FUNCARGNAME);
            return;
        }
        // Concatenate function prefix
        name = buffer;
        sprintf(buffer, "%s.%s", current_function->dato.nombre, arg);
    } else name = arg; // if not in function, name is the original
    PosicionLista p = buscaLS(l, name); // search for name
    if(p != finalLS(l)){
        // If in list, it's redeclared
        throw_semantic_error(name, REDECLARATION);
    } else {
        // Add id to list
        Simbolo aux;
        aux.nombre = strdup(name);
        aux.tipo = type;
        if(type == FUNCION) aux.valor = 0;
        insertaLS(l, finalLS(l), aux);
    }
}

// This method searches for FUNCTION in ls
PosicionLista get_function(char* arg){
    PosicionLista p = buscaLS(l, arg);
    if(p == finalLS(l) ){
        throw_semantic_error(arg, NOTDECLARED);
        return NULL;
    }
    if(p->sig->dato.tipo != FUNCION){
        throw_semantic_error(arg, NOTAFUNCTION);
    }
    return p->sig;
}

// This method searches for VARIABLE, CONSTANT or ARGUMENT in LS
void get_id(char* arg, int types){
    PosicionLista p = NULL;
    // If in function, add prefix
    if(current_function != NULL && strcmp(current_function->dato.nombre,arg) != 0){
        sprintf(buffer, "%s.%s", current_function->dato.nombre, arg);
        name = buffer;
    } else name = arg;
    // Search for identifier
    p = buscaLS(l, name);
    if(p == finalLS(l)){
        // If we didn't find it, semantic error, not declared
        throw_semantic_error(name, NOTDECLARED);
    } else {
        Simbolo sim = recuperaLS(l, p);
        if((types & sim.tipo) == 0)
            throw_semantic_error(name, WRONGTYPE);
    }
}

void throw_semantic_error(char* arg, int code){
    printf("Error en la línea %d: %s %s\n", yylineno, arg, errores[code]);
    errores_semanticos++;
}

int ok() {
    return !(errores_lexicos + errores_sintacticos + errores_semanticos);
}

void imprimirLS(){
    // Recorrido y generación de .data
    PosicionLista p = inicioLS(l);
    while (p != finalLS(l)) {
        Simbolo aux = recuperaLS(l,p);
        // Volcar info del símbolo
        switch(aux.tipo){
            case VARIABLE:
            case CONSTANTE:
            case ARGUMENTO:
            case FUNCION:
                printf("_%s: .word 0\n", aux.nombre);
                break;
            case CADENA:
                printf("$str%d: %s\n",aux.valor, aux.nombre);
                break;
        }
        p = siguienteLS(l,p);
    }
}



