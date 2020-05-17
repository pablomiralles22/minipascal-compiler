#ifndef __CODE_GEN__
#define __CODE_GEN__

#include "listaCodigo.h"

// expression -> ...

ListaC expr_num(char* arg);
ListaC expr_id(char* arg);
ListaC expr_op(ListaC arg1, ListaC arg2, char op);
ListaC expr_paren(ListaC arg);
ListaC expr_neg(ListaC arg);

// statement -> ...

ListaC stat_assign(char* arg1, ListaC arg2);
ListaC stat_write(ListaC arg);
ListaC stat_read(ListaC arg);
ListaC stat_if(ListaC arg1, ListaC arg2);
ListaC stat_if_else(ListaC arg1, ListaC arg2, ListaC arg3);
ListaC stat_while(ListaC arg1, ListaC arg2);
ListaC stat_comp(ListaC arg);
ListaC stat_for(char* arg1, ListaC arg2, ListaC arg3, ListaC arg4);

// statements -> ...

ListaC stats_stat(ListaC arg);
ListaC stats_claus(ListaC arg1, ListaC arg2);

// optional_statements -> ...

ListaC optstat_lambda();
ListaC optstat_stats(ListaC arg);

// compound_statement -> ...

ListaC compstat_optstat(ListaC arg);

// print_* -> ...

ListaC printit_exp(ListaC arg);
ListaC printit_str(int arg);
ListaC printl_printit(ListaC arg);
ListaC printl_claus(ListaC arg1, ListaC arg2);

// read_list -> ...

ListaC readl_id(char* arg);
ListaC readl_claus(ListaC arg1, char* arg2);

// constants -> ...

ListaC const_assign(char* arg1, ListaC arg2);
ListaC const_claus(ListaC arg1, char* arg2, ListaC arg3);

// declarations -> ...

ListaC decl_id(ListaC arg);
ListaC decl_const(ListaC arg1, ListaC arg2);
ListaC decl_lambda();

// program -> ...

ListaC program_output(ListaC decl, ListaC opt_stat);

void imprimirCodigo(ListaC codigo);

#endif
