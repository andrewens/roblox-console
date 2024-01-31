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

	-- const (test cases)
	local MULTI_LINE_TEXT =
		"Deli Selected\nHoney\nUncured Ham\nContains up to 24% of a seasoning solution\nNo nitrites or nitrates added\nNot preserved * Keep Refrigerated below 40 degrees F at all times"
	local TEXT_ARRAY_BY_NEW_LINES = string.split(MULTI_LINE_TEXT, "\n")
	local TEXT_ARRAY_16_CHARS_PER_LINE = {
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
	local TEXT_ARRAY_8_CHARS_PER_LINE = {
		-- text wrapping gets ugly when the words are longer than Console.MaxCharactersPerLine
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
		"solution", -- note that "solution" got put on a new line because it doesn't fit the previous line
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
	it("Console.MaxCharactersPerLine can be get/set to a natural number", function()
		local MyConsole = Console.new()

		-- Console.MaxCharactersPerLine should have a default value of 16
		shouldHaveType(MyConsole.MaxCharactersPerLine, "number")
		shouldBeEqual(MyConsole.MaxCharactersPerLine, 16)

		-- Console.MaxCharactersPerLine should be writable
		local newCharsPerLine = 32
		MyConsole.MaxCharactersPerLine = newCharsPerLine
		shouldBeEqual(MyConsole.MaxCharactersPerLine, newCharsPerLine)

		-- Console.MaxCharactersPerLine gets clamped/truncated into a natural number
		MyConsole.MaxCharactersPerLine = 0
		shouldBeEqual(MyConsole.MaxCharactersPerLine, 1) -- it gets clamped

		MyConsole.MaxCharactersPerLine = 3.678
		shouldBeEqual(MyConsole.MaxCharactersPerLine, 3) -- it gets truncated

		-- Console.MaxCharactersPerLine can't be a non-number value
		shouldError(function()
			MyConsole.MaxCharactersPerLine = "string"
		end)
		shouldError(function()
			MyConsole.MaxCharactersPerLine = {}
		end)
	end)

	-- methods
	it("Console:IsInstance(...) returns true if given the Instance rendering the Console", function()
		-- An explicit reference to the Console's Instance is not given because in practice
		-- you should not be referencing the Console's Instance directly.
		-- However, in order to properly test that the Console renders correctly, it is necessary
		-- to have some mechanism of ensuring that the Console does actually produce some sort of
		-- Instance (and that it actually renders text, as per the other tests.)
		local testName = "MyConsole"
		local ScreenGui = Instance.new("ScreenGui")

		-- put the Console in an arbitrary screen gui
		local MyConsole = Console.new()
		MyConsole.Name = testName
		MyConsole.Parent = ScreenGui

		-- Console:IsInstance(<RBXInstance>) should tell us if a given Instance is the Console's rendered TextBox or whatever
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
			MyConsole:SetText(MULTI_LINE_TEXT)

			local Lines = MyConsole:GetLines()
			shouldHaveType(Lines, "table")

			for i, str in TEXT_ARRAY_BY_NEW_LINES do
				shouldBeEqual(str, Lines[i])
			end
			shouldBeEqual(#TEXT_ARRAY_BY_NEW_LINES, #Lines)
		end
	)
	it(
		"Console:GetLines(true) returns an array of every line in the Console's text buffer, accounting for text wrapping per Console.MaxCharactersPerLine",
		function()
			local MyConsole = Console.new()

			-- Console:GetLines(true) for 16 max chars per line
			MyConsole.MaxCharactersPerLine = 16
			MyConsole:SetText(MULTI_LINE_TEXT)
			local Lines = MyConsole:GetLines(true) -- accountForTextWrapping = true

			shouldHaveType(Lines, "table")
			for i, str in TEXT_ARRAY_16_CHARS_PER_LINE do
				shouldBeEqual("'" .. str .. "'", "'" .. Lines[i] .. "'") -- added quotes so you can see empty spaces
			end
			shouldBeEqual(#TEXT_ARRAY_16_CHARS_PER_LINE, #Lines)

			-- Console:GetLines(true) for 8 max chars per line
			MyConsole.MaxCharactersPerLine = 8
			Lines = MyConsole:GetLines(true) -- accountForTextWrapping = true
			shouldHaveType(Lines, "table")

			for i, str in TEXT_ARRAY_8_CHARS_PER_LINE do
				shouldBeEqual("'" .. str .. "'", "'" .. Lines[i] .. "'") -- added quotes so you can see empty spaces
			end
			shouldBeEqual(#TEXT_ARRAY_8_CHARS_PER_LINE, #Lines)
		end
	)

	-- render
	it("Every line in Console (accounting for text wrap) is rendered as a TextLabel", function()
		local MyConsole = Console.new()

		-- retrieve the Instance of the Console
		local consoleName = "MyConsole"
		local ConsoleInstance
		local ScreenGui = Instance.new("ScreenGui")
		MyConsole.Name = consoleName
		MyConsole.Parent = ScreenGui
		ConsoleInstance = ScreenGui:FindFirstChild(consoleName)
		shouldHaveType(ConsoleInstance, "Instance")

		local function textShouldBeRendered()
			-- every text line should have a TextLabel
			local RenderedTextLabels = {} -- TextLabel --> true
			for i, line in MyConsole:GetLines(true) do
				local TextLabel = ConsoleInstance:FindFirstChild("Line" .. i)
				shouldHaveType(TextLabel, "Instance")
				shouldBeEqual(TextLabel.Text, line)
				RenderedTextLabels[TextLabel] = true
			end

			-- check for extraneous leftover TextLabels that didn't get cleaned up
			for i, TextLabel in ConsoleInstance:GetChildren() do
				if TextLabel:IsA("TextLabel") and not RenderedTextLabels[TextLabel] then
					error(
						"Console rendered an extra TextLabel: "
							.. tostring(TextLabel.Name)
							.. ".Text = "
							.. tostring(TextLabel.Text)
					)
				end
			end
		end

		textShouldBeRendered()

		MyConsole:SetText(MULTI_LINE_TEXT)
		MyConsole.MaxCharactersPerLine = 16
		textShouldBeRendered()

		MyConsole.MaxCharactersPerLine = 8
		textShouldBeRendered()

		MyConsole:AddText("dfkhkdfjkhjdkafjhklajfdkhlfkjdksdfjkdsajfklasd")
		textShouldBeRendered()

		MyConsole:SetText("")
		textShouldBeRendered()
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
