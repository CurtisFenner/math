# math
A simple computer algebra system written in Lua.

# Usage:

Run program on an input, where the system picks the most promising step at each moment.

    lua engine/math.lua [=, [+, 5, x], 0]

Run in "interactive" mode, where the user selects which step to follow next:

    lua engine/math.lua interactive [=, [+, 5, x], 0]

Or,

    lua engine/math.lua interactive

and enter the S-expression at the prompt.

The expression is passed in as an S-expression, where [] are used to denote lists.
