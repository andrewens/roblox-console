local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Maid = require(script:FindFirstChild("Maid"))

local function terminal(ScrollingFrame, Programs)
	--[[
		@param: ScrollingFrame
		@param: table Programs
			{ string commandName --> function(Console): nil }
		@return: Maid
	]]

	-- const
	local NUM_EXTRA_LINES = 6

	-- var
	local TerminalMaid = Maid()
	local InputMaid = Maid()
	local terminalIsRunning = true
	local TextBox

	local readOnlyText = ""
	local readOnlyLength = 0

	-- Console interface
	local function output(text)
		--[[
			@param: string text
			@post: renders text in Terminal
		]]

		local textHeight = TextBox.TextBounds.Y + NUM_EXTRA_LINES * TextBox.TextSize
		readOnlyText = readOnlyText .. text
		readOnlyLength = string.len(readOnlyText)

		TextBox.Text = readOnlyText
		TextBox.CursorPosition = readOnlyLength + 1
		TextBox.Size = UDim2.new(1, 0, 0, textHeight)
		ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, textHeight)
		ScrollingFrame.CanvasPosition = Vector2.new(0, textHeight)
	end
	local function input(prompt)
		--[[
			@param: string prompt
			@post: outputs prompt to screen
			@post: yields until return is pressed
		]]

		local enterPressed = false
		local function focusLost(...)
			enterPressed = ...
			if enterPressed then
				TextBox:CaptureFocus()
			end
		end

		InputMaid:DoCleaning()
		InputMaid(TextBox.FocusLost:Connect(focusLost))

		-- collect user input & wait until user presses Return
		output(prompt)
		while not enterPressed do
			task.wait()
		end

		InputMaid:DoCleaning()

		local userInput = string.sub(TextBox.Text, readOnlyLength + 1, -1)
		userInput = string.gsub(userInput, "%c", "") -- sanitize the input from control characters
		readOnlyText = readOnlyText .. userInput
		readOnlyLength = string.len(readOnlyText)

		return userInput
	end
	local Console = {
		input = input,
		output = output,
	}

	-- terminal functions
	local function cursorPositionChanged()
		-- disallow moving cursor into existing output
		if TextBox.CursorPosition > 0 and TextBox.CursorPosition < readOnlyLength + 2 then
			TextBox.CursorPosition = readOnlyLength + 2
			TextBox:CaptureFocus()
		end
	end
	local function textChanged()
		-- disallow deleting existing output
		if string.len(TextBox.Text) < readOnlyLength then
			TextBox.Text = readOnlyText
		end
	end
	local function commandLine(prompt)
		local args = Console.input(prompt)
		args = string.split(args, " ")
		local commandName = args[1]

		if Programs[commandName] then
			table.remove(args, 1)
			local s, msg = pcall(Programs[commandName], Console, table.unpack(args))
			if not s then
				Console.output("\n" .. msg .. "\n")
			end
		elseif commandName ~= "" then
			Console.output('\n"' .. commandName .. '" is not a command\n')
		end
	end
	local function init()
		TextBox = Instance.new("TextBox")
		TextBox.Size = UDim2.new(1, 0, 1, 0)
		TextBox.Font = Enum.Font.Code
		TextBox.ClearTextOnFocus = false
		TextBox:SetAttribute("class", "ConsoleText")
		TextBox.TextWrapped = true
		TextBox.TextXAlignment = Enum.TextXAlignment.Left
		TextBox.TextYAlignment = Enum.TextYAlignment.Top
		TextBox.Text = ""
		TextBox.Parent = ScrollingFrame
		TerminalMaid(TextBox)

		TextBox:GetPropertyChangedSignal("Text"):Connect(textChanged)
		TextBox:GetPropertyChangedSignal("CursorPosition"):Connect(cursorPositionChanged)

		TerminalMaid(function()
			terminalIsRunning = false
		end)

		task.spawn(function()
			while terminalIsRunning do
				commandLine("\n" .. LocalPlayer.Name .. " > ")
				task.wait()
			end
		end)
	end

	init()

	return TerminalMaid
end
return terminal
