# SWRLtoDatalog
A compiler from SWRL to Datalog in Lua using LPeg to generate the AST.

I used Lua version 5.1 and LPeg version 1.0.1.

### Current Status
We only deal with simple Datalog (no negation).

### Known bugs
.

### Using the program
To use it, from the main directory in this repository type in the command line:

``lua Test.lua``

if your version is 5.1, or

``lua5.1 Test.lua``

if newer.

These just run our test cases. If you wish to utilize the program for any other queries you have, just access them via the functions:

``ParseSWRL.parseInput(fileName)``

from ``ParseSWRL.lua`` to just generate the AST, or

``GenerateDatalog.generateOutput(fileName, index)``

from ``GenerateDatalog.lua``, which uses the previous function to generate the AST and creates a Datalog file.
