# Minipascal Compiler
## What is Minipascal?
Minipascal is simplified version of Pascal, with the following restrictions:
* There are only integer constants and variables. This means that True or False are handled as integers: 0 for False and anything else is True.
* There aren't relational and logical operators.
* There are no procedures, only functions.

Syntax examples can be found in the Unit Testing directory.

## How to use
Just run the *make* command. The compiler only takes one argument, the incoming program. Redirect the standard output to the file of your liking. The output is a program written in MIPS ensambler, executable using spim or Mars.
