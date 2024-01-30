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
    local function shouldThrow(f, msg)
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
    it("Console.Name can be get & set to strings", function()
        local testName = "MyConsole"
        local MyConsole = Console.new()

        -- console should already have a name property that's a string
        shouldHaveType(MyConsole.Name, "string")

        -- console name should be writable
        MyConsole.Name = testName
        shouldBeEqual(MyConsole.Name, testName)
    end)
    it("Console.Parent can be get & set to nil/Instances", function()
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

        -- setting Console.Parent to non-Instance values should error
        local badValue = "string"
        shouldThrow(function()
            MyConsole.Parent = badValue
        end, "Setting Console.Parent = " .. tostring(badValue) .. " failed to error")
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
end
