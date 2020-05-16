#include "code_gen.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "assert.h"
#define NREG 10
// SYSCALLS
#define READSYSCALL "5"
#define WRITESYSCALLSTR "4"
#define WRITESYSCALLVAR "1"

/*
 * Utilidades para etiquetas
 */

int tag_count = 1;

char* new_tag() {
    char aux[16];
    sprintf(aux, "$l%d", tag_count++);
    return strdup(aux);
}

/*
 * Variable Operacion global para las functiones
 */

Operacion oper;

void set_oper(char* res, char* op, char* arg1, char* arg2) {
    oper.res = res;
    oper.op = op;
    oper.arg1 = arg1;
    oper.arg2 = arg2;
}

/*
 * Manejador de registros libres
 */
char registros[NREG] = {0};

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

/*
 * Otras utilidades
 */
char* concatena(char* arg1, char* arg2) {
    char* aux = (char*)malloc(strlen(arg1) + strlen(arg2) + 1);
    sprintf(aux, "%s%s", arg1, arg2);
    return aux;
}

char* get_str_tag(int count) {
    char buffer[32];
    sprintf(buffer, "$str%d", count);
    return strdup(buffer);
}

// expression -> ...
ListaC expr_id(char* arg) {
    ListaC ret = creaLC();
    set_oper(obtener_reg(), "lw", concatena("_", arg), NULL);
    insertaLC(ret, finalLC(ret), oper);
    guardaResLC(ret, oper.res);
    return ret;
}

ListaC expr_num(char* arg) {
    ListaC ret = creaLC();
    set_oper(obtener_reg(), "li", arg, NULL);
    insertaLC(ret, finalLC(ret), oper);
    guardaResLC(ret, oper.res);
    return ret;
}

ListaC expr_op(ListaC arg1, ListaC arg2, char op) {
    concatenaLC(arg1, arg2);
    char* operation;
    switch (op) {
        case '+':
            operation = "add";
            break;
        case '-':
            operation = "sub";
            break;
        case '*':
            operation = "mul";
            break;
        case '/':
            operation = "div";
            break;
    }
    set_oper(recuperaResLC(arg1), operation, recuperaResLC(arg1),
             recuperaResLC(arg2));
    insertaLC(arg1, finalLC(arg1), oper);
    liberaLC(arg2);
    liberarReg(oper.arg2);
    return arg1;
}

ListaC expr_paren(ListaC arg) { return arg; }

ListaC expr_neg(ListaC arg) {
    set_oper(recuperaResLC(arg), "neg", recuperaResLC(arg), NULL);
    insertaLC(arg, finalLC(arg), oper);
}

/*
 * statement -> ...
 */

ListaC stat_assign(char* arg1, ListaC arg2) {
    set_oper(recuperaResLC(arg2), "sw", concatena("_", arg1), NULL);
    insertaLC(arg2, finalLC(arg2), oper);
    liberarReg(recuperaResLC(arg2));
    return arg2;
}

ListaC stat_write(ListaC arg) { return arg; }
ListaC stat_read(ListaC arg) { return arg; }

ListaC stat_if(ListaC arg1, ListaC arg2) {
    char* tag = new_tag();
    set_oper(recuperaResLC(arg1), "beqz", tag, NULL);
    insertaLC(arg1, finalLC(arg1), oper);
    concatenaLC(arg1, arg2);
    liberaLC(arg2);
    set_oper(tag, "tag", NULL, NULL);
    insertaLC(arg1, finalLC(arg1), oper);
    return arg1;
}

ListaC stat_if_else(ListaC arg1, ListaC arg2, ListaC arg3) {
    char *tag_if = new_tag(), *tag_else = new_tag();
    set_oper(recuperaResLC(arg1), "beqz", tag_else, NULL);
    insertaLC(arg1, finalLC(arg1), oper);
    concatenaLC(arg1, arg2);
    liberaLC(arg2);
    set_oper(tag_if, "b", NULL, NULL);
    insertaLC(arg1, finalLC(arg1), oper);
    set_oper(tag_else, "tag", NULL, NULL);
    insertaLC(arg1, finalLC(arg1), oper);
    concatenaLC(arg1, arg3);
    liberaLC(arg3);
    set_oper(tag_if, "tag", NULL, NULL);
    insertaLC(arg1, finalLC(arg1), oper);
    return arg1;
}

ListaC stat_while(ListaC arg1, ListaC arg2) {
    char *tag_start = new_tag(), *tag_end = new_tag();
    set_oper(tag_start, "tag", NULL, NULL);
    insertaLC(arg1, inicioLC(arg1), oper);
    set_oper(recuperaResLC(arg1), "beqz", tag_end, NULL);
    concatenaLC(arg1, arg2);
    liberaLC(arg2);
    set_oper(tag_start, "b", NULL, NULL);
    insertaLC(arg1, finalLC(arg1), oper);
    set_oper(tag_end, "tag", NULL, NULL);
    insertaLC(arg1, finalLC(arg1), oper);
    return arg1;
}

ListaC stat_comp(ListaC arg) { return arg; }

ListaC stat_for(char* arg1, ListaC arg2, ListaC arg3, ListaC arg4) {
    ListaC ret, advance_iteration, while_loop;
    ret = stat_assign(arg1, arg2);
    advance_iteration =
        stat_assign(arg1, expr_op(expr_id(arg1), expr_num("1"), '+'));
    concatenaLC(arg4, advance_iteration);
    liberaLC(advance_iteration);
    while_loop = stat_while(expr_op(arg3, expr_id(arg1), '-'), arg4);
    concatenaLC(ret, while_loop);
    liberaLC(while_loop);
    return ret;
}

/*
 * statements -> ...
 */

ListaC stats_stat(ListaC arg) { return arg; }

ListaC stats_claus(ListaC arg1, ListaC arg2) {
    concatenaLC(arg1, arg2);
    liberaLC(arg2);
    return arg1;
}

/*
 * optional_statements -> ...
 */

ListaC optstat_lambda() { return creaLC(); }

ListaC optstat_stats(ListaC arg) { return arg; }

/*
 * compound_statement -> ...
 */

ListaC compstat_optstat(ListaC arg) { return arg; }

/*
 * print_* -> ...
 */

ListaC printit_exp(ListaC arg) {
    set_oper("$v0", "li", WRITESYSCALLVAR, NULL);
    insertaLC(arg, finalLC(arg), oper);
    set_oper("$a0", "move", recuperaResLC(arg), NULL);
    insertaLC(arg, finalLC(arg), oper);
    set_oper(NULL, "syscall", NULL, NULL);
    insertaLC(arg, finalLC(arg), oper);
    liberarReg(recuperaResLC(arg));
    return arg;
}

ListaC printit_str(int arg) {
    ListaC res = creaLC();
    set_oper("$v0", "li", WRITESYSCALLSTR, NULL);
    insertaLC(res, finalLC(res), oper);
    set_oper("$a0", "la", get_str_tag(arg), NULL);
    insertaLC(res, finalLC(res), oper);
    set_oper(NULL, "syscall", NULL, NULL);
    insertaLC(res, finalLC(res), oper);
    return res;
}

ListaC printl_printit(ListaC arg) { return arg; }

ListaC printl_claus(ListaC arg1, ListaC arg2) {
    concatenaLC(arg1, arg2);
    liberaLC(arg2);
    return arg1;
}

/*
 * read_list->...
 */

ListaC readl_id(char* arg) {
    ListaC res = creaLC();
    set_oper("$v0", "li", READSYSCALL, NULL);
    insertaLC(res, finalLC(res), oper);
    set_oper(NULL, "syscall", NULL, NULL);
    insertaLC(res, finalLC(res), oper);
    set_oper("$v0", "sw", concatena("_", arg), NULL);
    insertaLC(res, finalLC(res), oper);
    return res;
}

ListaC readl_claus(ListaC arg1, char* arg2) {
    set_oper("$v0", "li", READSYSCALL, NULL);
    insertaLC(arg1, finalLC(arg1), oper);
    set_oper(NULL, "syscall", NULL, NULL);
    insertaLC(arg1, finalLC(arg1), oper);
    set_oper("$v0", "sw", concatena("_", arg2), NULL);
    insertaLC(arg1, finalLC(arg1), oper);
    return arg1;
}

/*
 * constants -> ...
 */
ListaC const_assign(char* arg1, ListaC arg2) { return stat_assign(arg1, arg2); }

ListaC const_claus(ListaC arg1, char* arg2, ListaC arg3) {
    ListaC aux = const_assign(arg2, arg3);
    concatenaLC(arg1, aux);
    liberaLC(aux);
    return arg1;
}

/*
 * declarations -> ...
 */

ListaC decl_id(ListaC arg) { return arg; }

ListaC decl_const(ListaC arg1, ListaC arg2) {
    concatenaLC(arg1, arg2);
    liberaLC(arg2);
    return arg1;
}

ListaC decl_lambda() { return creaLC(); }

/*
 * program ->...
 */

ListaC program_output(ListaC decl, ListaC comp_stat) {
    concatenaLC(decl, comp_stat);
    liberaLC(comp_stat);
    set_oper("main", "tag", NULL, NULL);
    insertaLC(decl, inicioLC(decl), oper);
    set_oper("$ra", "jr", NULL, NULL);
    insertaLC(decl, finalLC(decl), oper);
    return decl;
}

/*
 * Generate code
 */
void imprimirCodigo(ListaC codigo) {
    PosicionListaC p = inicioLC(codigo);
    printf("\n###################\n");
    printf("# Seccion de codigo\n");
    printf("\t.text\n");
    printf("\t.globl main\n");
    while (p != finalLC(codigo)) {
        oper = recuperaLC(codigo, p);
        if (strcmp(oper.op, "tag") == 0) {
            printf("%s:\n", oper.res);
        } else {
            printf("\t%s ", oper.op);
            if (oper.res) printf("%s", oper.res);
            if (oper.arg1) printf(",%s", oper.arg1);
            if (oper.arg2) printf(",%s", oper.arg2);
            printf("\n");
        }
        p = siguienteLC(codigo, p);
    }
}
