return {
    --[[
        Format:

        Very first line -- max number of characters per line

        1. Input to TextBuffer.addText
        2. Expected state of TextBuffer
    ]]

    -- MAX_CHARS_PER_LINE
    4,

    -- Test #1
    "a",
    "a",

    -- Test #2
    "b",
    "ab",
    -- Test #3
    "c",
    "abc",

    -- Test #4
    "d",
    "abcd",

    -- Test #5
    "e",
    "abcd\ne",

    -- Test #6
    "fg",
    "abcd\nefg",

    -- Test #7
    "hi",
    "abcd\nefgh\ni",

    -- Test #8
    "jkl",
    "abcd\nefgh\nijkl",

    -- Test #9
    "mnop",
    "abcd\nefgh\nijkl\nmnop",

    -- Test #10
    "qrstu",
    "abcd\nefgh\nijkl\nmnop\nqrst\nu",

    -- Test #11
    "vwxyz",
    "abcd\nefgh\nijkl\nmnop\nqrst\nuvwx\nyz",

    -- Test #12
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
    "abcd\nefgh\nijkl\nmnop\nqrst\nuvwx\nyzAB\nCDEF\nGHIJ\nKLMN\nOPQR\nSTUV\nWXYZ",
}