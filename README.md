# math
A simple computer algebra system written in Lua.

# Usage:

Run program on an input, where the system picks the most promising step at each moment.

    lua math.lua [=, [+, 5, x], 0]

Run in "interactive" mode, where the user selects which step to follow next:

    lua math.lua interactive [=, [+, 5, x], 0]

The expression is passed in as an S-expression, where [] are used to denote lists.
