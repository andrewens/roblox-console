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

	-- properties
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

	-- methods
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
	it("Console:GetText() and Console:SetText(...) read/overwrite the Console's text buffer", function()
		local MyConsole = Console.new()

		-- Console's default text should be a hello-world intro
		local INTRO_TEXT = "Welcome to `roblox-console`!"
		shouldBeEqual(MyConsole:GetText(), INTRO_TEXT)

		-- Console:SetText(...) should write to the Console's text
		local newText = "The quick brown fox jumped over the lazy dog."
		MyConsole:SetText(newText)
		shouldBeEqual(MyConsole:GetText(), newText)

		-- Console:SetText(...) should only allow strings
		shouldError(function()
			MyConsole:SetText()
		end)
		shouldError(function()
			MyConsole:SetText({})
		end)
		shouldError(function()
			MyConsole:SetText(math.pi)
		end)
		shouldError(function()
			MyConsole:SetText(Instance.new("Part"))
		end)
	end)
	it("Console:AddText(...) appends text to the Console's text buffer", function()
		local MyConsole = Console.new()

		-- Console:AddText(...) appends new text
		local startingText = MyConsole:GetText()
		local addlText = " Lorem Ipsum"

		MyConsole:AddText(addlText)
		shouldBeEqual(MyConsole:GetText(), startingText .. addlText)

		MyConsole:AddText(addlText)
		shouldBeEqual(MyConsole:GetText(), startingText .. addlText .. addlText)

		-- Console:AddText() should only allow strings
		shouldError(function()
			MyConsole:AddText()
		end)
		shouldError(function()
			MyConsole:AddText({})
		end)
		shouldError(function()
			MyConsole:AddText(math.pi)
		end)
	end)
	it(
		"Console:GetLines() returns an array of every line in the Console's text buffer, split by \\n characters.",
		function()
			local MyConsole = Console.new()

			local multiLineText =
				"Deli Selected\nHoney\nUncured Ham\nContains up to 24% of a seasoning solution\nNo nitrites or nitrates added\nNot preserved * Keep Refrigerated below 40 degrees F at all times"
			local textArray = string.split(multiLineText, "\n")
			MyConsole:SetText(multiLineText)

			local Lines = MyConsole:GetLines()
			shouldHaveType(Lines, "table")
			shouldBeEqual(#textArray, #Lines)

			for i, str in textArray do
				shouldBeEqual(str, Lines[i])
			end
		end
	)
	it(
		"Console:GetLines(true) returns an array of every line in the Console's text buffer, accounting for text wrapping per Console.CharactersPerLine",
		function()
			local MyConsole = Console.new()
			local multiLineText =
				"Deli Selected\nHoney\nUncured Ham\nContains up to 24% of a seasoning solution\nNo nitrites or nitrates added\nNot preserved * Keep Refrigerated below 40 degrees F at all times"

			local charsPerLine = 16
			local textArray = {
				"Deli Selected",
				"Honey",
				"Uncured Ham",
				"Contains up to", -- text wraps at the space
				"24% of a",
				"seasoning",
				"solution",
				"No nitrites or",
				"nitrates added",
				"Not preserved *",
				"Keep",
				"Refrigerated",
				"below 40 degrees",
				"F at all times",
			}
			MyConsole.CharactersPerLine = charsPerLine
			MyConsole:SetText(multiLineText)
			local Lines = MyConsole:GetLines(true) -- accountForTextWrapping = true

			shouldHaveType(Lines, "table")
			for i, str in textArray do
				shouldBeEqual("'" .. str .. "'", "'" .. Lines[i] .. "'") -- added quotes so you can see empty spaces
			end
			shouldBeEqual(#textArray, #Lines)

			-- text wrapping gets ugly when the words are longer than Console.CharactersPerLine
			charsPerLine = 8
			textArray = {
				"Deli",
				"Selected",
				"Honey",
				"Uncured",
				"Ham",
				"Contains",
				"up to",
				"24% of a",
				"seasonin",
				"g",
				"solution", -- note that "solution" got put on a new line because it doesn't fit
				"No",
				"nitrites",
				"or",
				"nitrates",
				"added",
				"Not",
				"preserve",
				"d * Keep", -- no new line here for '* Keep' because it fits
				"Refriger",
				"ated",
				"below 40",
				"degrees",
				"F at all",
				"times",
			}

			MyConsole.CharactersPerLine = charsPerLine
			Lines = MyConsole:GetLines(true) -- accountForTextWrapping = true

			shouldHaveType(Lines, "table")
			for i, str in textArray do
				shouldBeEqual("'" .. str .. "'", "'" .. Lines[i] .. "'") -- added quotes so you can see empty spaces
			end
			shouldBeEqual(#textArray, #Lines)
		end
	)

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
