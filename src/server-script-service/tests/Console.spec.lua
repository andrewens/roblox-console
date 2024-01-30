return function()
    -- dependency
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Console = require(ReplicatedStorage:FindFirstChild("Console"))

    -- private
    local function shouldHaveType(v1, typeName)
        if typeof(v1) ~= typeName then
            error(tostring(v1) .. " isn't a " .. tostring(typeName) .. "!")
        end
    end
    local function shouldBeEqual(v1, v2)
        if not (v1 == v2) then
            error(tostring(v1) .. " ~= " .. tostring(v2))
        end
    end
    local function shouldError(f, msg)
        local s = pcall(f)
        if s then
            error(msg or tostring(f) .. " failed to throw error!")
        end
    end

    -- init
    it("Console.new() returns a table", function()
        shouldHaveType(Console.new, "function")
        shouldHaveType(Console.new(), "table")
    end)
    it("Console.Name can be get/set to strings", function()
        local testName = "MyConsole"
        local MyConsole = Console.new()

        -- Console.Name should always be a string
        shouldHaveType(MyConsole.Name, "string")
        shouldError(function()
            MyConsole.Name = {}
        end)

        -- Console.Name should be writable
        MyConsole.Name = testName
        shouldBeEqual(MyConsole.Name, testName)
    end)
    it("Console.Parent can be get/set to nil/Instances", function()
        local testName = "MyConsole"
        local MyConsole = Console.new()

        -- Console.Parent should equal nil by default
        shouldBeEqual(MyConsole.Parent, nil)

        -- Setting Console.Parent = <Instance> | nil shouldn't error
        local ScreenGui = Instance.new("ScreenGui")
        MyConsole.Parent = ScreenGui
        shouldBeEqual(MyConsole.Parent, ScreenGui)

        MyConsole.Parent = nil
        shouldBeEqual(MyConsole.Parent, nil)

        -- Setting Console.Parent to non-Instance values should error
        local badValue = "string"
        shouldError(function()
            MyConsole.Parent = badValue
        end)
    end)
    it("Console:IsInstance(...) returns true if given the Instance rendering the Console", function()
        local testName = "MyConsole"
        local ScreenGui = Instance.new("ScreenGui")

        -- put the Console in an arbitrary screen gui
        local MyConsole = Console.new()
        MyConsole.Name = testName
        MyConsole.Parent = ScreenGui

        -- Console == Instance should tell us if a given Instance is the Console's rendered TextBox or whatever
        -- the method & naming convention is :PascalCase() operator to match ROBLOX Instance fields
        local ConsoleInstance = ScreenGui:FindFirstChild(testName)
        shouldBeEqual(MyConsole:IsInstance(ConsoleInstance), true)
        shouldBeEqual(MyConsole:IsInstance(ScreenGui), false)
        shouldBeEqual(MyConsole:IsInstance(Instance.new("Part")), false)

        -- note that Instance == Console doesn't work because Console is still a table
        shouldBeEqual(MyConsole == ConsoleInstance, false)
        shouldBeEqual(MyConsole == ScreenGui, false)
    end)
    it("Console.CharactersPerLine can be get/set to a natural number", function()
        local MyConsole = Console.new()

        -- Console.CharactersPerLine should have a default value of 16
        shouldHaveType(MyConsole.CharactersPerLine, "number")
        shouldBeEqual(MyConsole.CharactersPerLine, 16)

        -- Console.CharactersPerLine should be writable
        local newCharsPerLine = 32
        MyConsole.CharactersPerLine = newCharsPerLine
        shouldBeEqual(MyConsole.CharactersPerLine, newCharsPerLine)

        -- Console.CharactersPerLine gets clamped/truncated into a natural number
        MyConsole.CharactersPerLine = 0
        shouldBeEqual(MyConsole.CharactersPerLine, 1) -- it gets clamped

        MyConsole.CharactersPerLine = 3.678
        shouldBeEqual(MyConsole.CharactersPerLine, 3) -- it gets truncated

        -- Console.CharactersPerLine can't be a non-number value
        shouldError(function()
            MyConsole.CharactersPerLine = "string"
        end)
        shouldError(function()
            MyConsole.CharactersPerLine = {}
        end)
    end)

    --[[
        History

        ... > Command Line

        (available commands)

        There should be automatic help for the commands...


        So as far as this command prompt is concerned, it:

        * Maintains a history buffer of text for the user
        * Allows inputting commands
        * Allows for the definition of commands

        Buffer
        Input
        Command

        What is a command?

        * A keyword
        * An operation (fn)
        * A set of arguments
        * A set of documentation

        1. Maintain a buffer
            * Input to it
                Console:Out(str)
            * Read from it
                Console:GetBuffer() --> { str }
                Console:GetLine()
            * Draw it on screen somehow
        2. Get user input
            Console:In(str)
    ]]
end
