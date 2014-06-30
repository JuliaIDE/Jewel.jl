# Jewel.jl

Jewel.jl is a collection of IDE related code. It also handles communication with Light Table, although this is entirely seperate (in the `LightTable` folder) and may be removed eventually.

It handles things such as:

* Extensible autocompletion
* Pulling code blocks out of files (given a cursor position)
* Finding relevant documentation or method definitions at the cursor
* Detecting the module a file belongs to
* Evaluation of code blocks with correct file, line and module data
