return {
    --[[
        Format:

        Lines #1 - #3 are inputs to commandLineInterface(...):
            1. table Programs
            2. Instance? Frame
            3. int? textSize
        Line #4 is 


        "<NIL>" is converted to nil at runtime
    ]]

    -- Test #1: Basic programs
    {
        programA = function(CLI, ...)

        end,
    },
    "<NIL>",
    "<NIL>",
    true,
}