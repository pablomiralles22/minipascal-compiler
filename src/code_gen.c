#include "code_gen.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "assert.h"
#define NREG 10

/*
 * Manejador de registros libres
 */
char registros[NREG] = {0};
Operacion oper;

char* obtener_reg() {
    for (int i = 0; i < NREG; i++)
        if (registros[i] == 0) {
            registros[i] = 1;
            char aux[16];
            sprintf(aux, "$t%d", i);
            return strdup(aux);
        }
    printf("Error: registros agotados\n");
    exit(1);
}

void liberarReg(char* reg) {
    if (reg[0] == '$' && reg[1] == 't') {
        int aux = reg[2] - '0';
        assert(aux >= 0);
        assert(aux < 10);
        registros[aux] = 0;
    }
}

char* concatena(char* arg1, char* arg2) {
    char* aux = (char*)malloc(strlen(arg1) + strlen(arg2) + 1);
    sprintf(aux, "%s%s", arg1, arg2);
    return aux;
}

// expression -> ...
ListaC expr_id(char* arg) {
    ListaC ret = creaLC();
    oper.op = "lw";
    oper.arg1 = concatena("_", arg);
    oper.arg2 = NULL;
    insertaLC(ret, finalLC(ret), oper);
    guardaResLC(ret, oper.res);
    return ret;
}

ListaC expr_num(char* arg) {
    ListaC ret = creaLC();
    oper.op = "li";
    oper.res = obtener_reg();
    oper.arg1 = arg;
    oper.arg2 = NULL;
    insertaLC(ret, finalLC(ret), oper);
    guardaResLC(ret, oper.res);
    return ret;
}

ListaC expr_op(ListaC arg1, ListaC arg2, char op) {
    concatenaLC(arg1, arg2);
    switch (op) {
        case '+':
            oper.op = "add";
            break;
        case '-':
            oper.op = "sub";
            break;
        case '*':
            oper.op = "mul";
            break;
        case '/':
            oper.op = "div";
            break;
    }
    oper.res = recuperaResLC(arg1);
    oper.arg1 = recuperaResLC(arg1);
    oper.arg2 = recuperaResLC(arg2);
    insertaLC(arg1, finalLC(arg1), oper);
    liberaLC(arg2);
    liberarReg(oper.arg2);
    return arg1;
}

ListaC expr_paren(ListaC arg) { return arg; }

ListaC expr_neg(ListaC arg) {
    oper.op = "neg";
    oper.res = recuperaResLC(arg);
    oper.arg1 = recuperaResLC(arg);
    oper.arg2 = NULL;
    insertaLC(arg, finalLC(arg), oper);
}

void imprimirCodigo(ListaC codigo) {
    PosicionListaC p = inicioLC(codigo);
    while (p != finalLC(codigo)) {
        oper = recuperaLC(codigo, p);
        printf("%s ", oper.op);
        if (oper.res) printf("%s", oper.res);
        if (oper.arg1) printf(",%s", oper.arg1);
        if (oper.arg2) printf(",%s", oper.arg2);
        printf("\n");
        p = siguienteLC(codigo, p);
    }
}

