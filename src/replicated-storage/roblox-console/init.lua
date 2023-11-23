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
	local ThreadMaid = Maid()
	local InputMaid = Maid()
	local terminalIsRunning = false
	local TextBox

	local readOnlyText = ""
	local readOnlyLength = 0
	local commandLineText = "\n" .. LocalPlayer.Name .. ">"

	-- private
	local function resizeTextBox()
		local textHeight = TextBox.TextBounds.Y + NUM_EXTRA_LINES * TextBox.TextSize
		TextBox.Size = UDim2.new(1, 0, 0, textHeight)
		ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, textHeight)
		ScrollingFrame.CanvasPosition = Vector2.new(0, textHeight)
	end
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

	-- public | Console interface
	local Console
	local function output(text)
		--[[
			@param: string text
			@post: renders text in Terminal
			@post: updates TextBox size & ScrollingFrame canvas size / position
			@return: string text (the same as the argument)
		]]

		-- set text / cursor position
		readOnlyText = readOnlyText .. text
		readOnlyLength = string.len(readOnlyText)
		TextBox.Text = readOnlyText
		TextBox.CursorPosition = readOnlyLength + 1

		-- adjust size
		resizeTextBox()

		return text
	end
	local function input(prompt)
		--[[
			@param: string prompt
			@post: outputs prompt to screen
			@post: yields until return is pressed
			@return: string userInput
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
	local function command(args)
		--[[
			@param: string args
			@post: executes the program named the same as the first arg (separated by space)
			@return: string | nil errorMessage
		]]

		-- trim leading spaces
		local i = 1
		while i <= string.len(args) and string.sub(args, i, i) == " " do
			i += 1
		end
		args = string.sub(args, i, string.len(args))

		-- string --> table
		args = string.split(args, " ")
		local commandName = args[1]

		-- first arg is the name of the program
		if Programs[commandName] then
			table.remove(args, 1)
			local s, msg = pcall(Programs[commandName], Console, table.unpack(args))
			if not s then
				return Console.output("\n" .. msg .. "\n")
			end
		elseif commandName ~= "" then
			return Console.output('\n"' .. commandName .. '" is not a command\n')
		end
	end
	local function destroy()
		--[[
			@post: Terminal GUI no longer exists
		]]
		TerminalMaid:DoCleaning()
	end
	local function clear()
		--[[
			@post: clear all text from terminal
		]]
		readOnlyText = ""
		readOnlyLength = 0
		resizeTextBox()
	end
	local function initialize(args)
		--[[
			@param: string | nil args
				- option to run a command on startup
			@post: command loop runs until terminated
		]]

		ThreadMaid:DoCleaning()
		ThreadMaid:GiveTask(InputMaid)
		ThreadMaid(function()
			terminalIsRunning = false
		end)
		if args then
			output(commandLineText .. args)
		end
		task.spawn(function()
			terminalIsRunning = true
			while terminalIsRunning do
				args = args or input(commandLineText)
				command(args)
				args = nil
				task.wait()
			end
		end)
	end
	local function terminate()
		ThreadMaid:DoCleaning()
	end

	Console = {
		input = input,
		output = output,
		command = command,
		clear = clear,
		destroy = destroy,
		Destroy = destroy, -- in case someone uses Quenty's Maid implementation
		initialize = initialize,
		terminate = terminate,
	}

	-- initialize the terminal
	TerminalMaid(ThreadMaid)

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

	return Console
end
return terminal
