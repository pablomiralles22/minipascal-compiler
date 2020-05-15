#ifndef __CODE_GEN__
#define __CODE_GEN__

#include "listaCodigo.h"

// extern ListaC lc;

// expression -> ...
ListaC expr_num(char* arg);
ListaC expr_id(char* arg);
ListaC expr_op(ListaC arg1, ListaC arg2, char op);
ListaC expr_paren(ListaC arg);
ListaC expr_neg(ListaC arg);
void imprimirCodigo(ListaC codigo);

#endif
