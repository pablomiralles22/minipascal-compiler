#include "semantic_analysis.h"

#include <stdio.h>
#define BUFFSIZE 1024
// Para errores
#define REDECLARATION 0
#define NOTDECLARED 1
#define WRONGTYPE 2
#define FUNCARGNAME 3
#define NOTAFUNCTION 4

char* errores[] = {"redeclarado", "no declarado", "no es del tipo adecuado",
                   "es el nombre de la función", "no es una función"};

char buffer[BUFFSIZE];
int parsing_func = 0;
PosicionLista current_function;

PosicionLista insert_id(char* name, int type, int value) {
    PosicionLista p = buscaLS(l, name);
    if (p != finalLS(l)) {
        return NULL;
    }
    Simbolo aux;
    aux.nombre = name;
    aux.valor = value;
    aux.tipo = type;
    insertaLS(l, finalLS(l), aux);
    return finalLS(l);
}

void parse_function_declaration(char* name) {
    parsing_func = 1;  // parsing function now
    current_function = insert_id(name, FUNCION, 0);
    if (current_function == NULL) {
        // function redeclared
        throw_semantic_error(name, REDECLARATION);
    }
}

void end_function_declaration() {
    parsing_func = 0;
    current_function = NULL;
}

void throw_semantic_error(char* arg, int code) {
    printf("Error en la línea %d: %s %s\n", yylineno, arg, errores[code]);
    errores_semanticos++;
}
