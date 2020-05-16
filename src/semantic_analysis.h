#ifndef __SEMANTIC_ANALYSIS__
#define __SEMANTIC_ANALYSIS__
#include "listaSimbolos.h"

extern Lista l;
extern int errores_semanticos;
extern int yylineno;

void parse_function_declaration();
void end_function_declaration();
void args_on();
void args_off();

#endif

