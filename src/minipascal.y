%{
    #include <stdio.h>
    #include <string.h>
    #include "listaSimbolos.h"
    #define BUFFSIZE 1024

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
%}

/* Tipos de datos */
%union {
    char *str;
}

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
identifiers : ID {insert_id($1, args_on ? ARGUMENTO : VARIABLE);}
            | identifiers COMMA ID {insert_id($3,args_on ? ARGUMENTO : VARIABLE);}
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
                                        if(current_function == NULL || strcmp(current_function->dato.nombre, $1))
                                            // si no estamos haciendo un return
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
print_item  : expression
            | STRING {
                        PosicionLista p = buscaLS(l, $1);
                        if(p == finalLS(l) || recuperaLS(l, p).tipo != CADENA /* TODO preguntar si puede pasar*/){
                            Simbolo aux;
                            aux.nombre = $1;
                            aux.tipo = CADENA;
                            aux.valor = contador_cadenas++;
                            insertaLS(l, finalLS(l), aux);
                        } 
                    }
            ;
read_list   : ID { get_id($1, VARIABLE); }
            | read_list COMMA ID { get_id($3, VARIABLE);}
            ;
expression  : expression PLUSOP expression
            | expression MINUSOP expression
            | expression MULTOP expression
            | expression DIVOP expression
            | MINUSOP expression
            | LPAREN expression RPAREN
            | ID { get_id($1, VARIABLE | CONSTANTE | ARGUMENTO); }
            | INTCONST
            | ID { get_id($1, FUNCION); } LPAREN arguments RPAREN {
                                                                        if(current_function->dato.valor != count_args)
                                                                        printf("Error en la línea %d: %s número incorrecto de argumentos\n", yylineno,$1);
                                                                  }
            ;
arguments   : { count_args = 1; } expressions
            |
            ;
expressions : expression
            | expressions COMMA expression { count_args++; }
%%

void yyerror(const char *msg){
    printf("Error en linea %d: %s\n", yylineno, msg);
    errores_sintacticos++;
}

void insert_id(char* arg, int type){
    // Si estamos en una función
    if(current_function != NULL){
        if(strcmp(arg, current_function->dato.nombre) == 0){
            // Nombre igual que nombre de función
            printf("Error en la línea %d: %s es el nombre de la función\n", yylineno, name);
            errores_semanticos++;
            return ;
        }
        name = buffer;
        sprintf(buffer, "%s_%s", current_function->dato.nombre, arg);
        if(type == ARGUMENTO)
            current_function->dato.valor++;
    } else name = arg;

    PosicionLista p = buscaLS(l, name);
    if(p != finalLS(l)){
        // Redeclaración de identificador
        printf("Error en la línea %d: %s redeclarado\n", yylineno, name);
        errores_semanticos++;
    } else {
        // Primera declaración de $1: es correcto
        Simbolo aux;
        aux.nombre = name;
        aux.tipo = type;
        if(type == FUNCION) aux.valor = 0;
        insertaLS(l, finalLS(l), aux);
    }
}

void get_id(char* arg, int types){
    PosicionLista p = NULL;
    if(current_function != NULL){
        // estamos en una función
        sprintf(buffer, "%s_%s", current_function->dato.nombre, arg);
        p = buscaLS(l, buffer);
    }
    if(p == NULL || p == finalLS(l))
        // si no lo he encontrado con el otro nombre o no estoy en una función
        p = buscaLS(l, arg);

    if(p == finalLS(l)){
        // Redeclaración de identificador
        printf("Error en la línea %d: %s no declarada\n", yylineno, arg);
        errores_semanticos++;
    } else {
        Simbolo sim = recuperaLS(l, p);
        if((types & sim.tipo) == 0) {
            printf("Error en la línea %d: %s no se esperaba\n", yylineno, arg);
            errores_semanticos++;
        } else {
            if(sim.tipo == FUNCTION) current_function = p;
        }
    }
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
                printf("_%s: .word 0\n", aux.nombre);
                break;
            case CADENA:
                printf("$str%d: %s\n",aux.valor, aux.nombre);
                break;
        }
        p = siguienteLS(l,p);
    }
}



