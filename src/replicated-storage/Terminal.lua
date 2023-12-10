--[[
    This is a command line GUI that you can embed into a ScrollingFrame Instance.

    Andrew Ens
    December 2023

    View this gist and more on my github:
        https://gist.github.com/andrewens/
]]

-- dependency
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Maid
do
	--[[
        From Andrew Ens' github gist:
            https://gist.github.com/andrewens/7897d3520dec32dcb69e0e4b600b07ca
    ]]

	-- private
	local function handleTask(task)
		local taskType = typeof(task)
		if taskType == "function" then
			task()
		elseif taskType == "Instance" then
			task:Destroy()
		elseif taskType == "RBXScriptConnection" then
			task:Disconnect()
		else -- tables & what have you
			(task.Destroy or task.destroy or task.Disconnect)(task)
		end
	end
	local function isValidTask(val)
		local valType = typeof(val)
		return valType == "function"
			or valType == "table" and (val.Destroy or val.destroy)
			or valType == "Instance"
			or valType == "RBXScriptConnection"
	end
	local function assertIsValidTask(val)
		if not isValidTask(val) then
			error(tostring(val) .. " (type=" .. typeof(val) .. ") is not a valid task for a Maid")
		end
	end

	-- public
	local function giveTask(self, newTask)
		assertIsValidTask(newTask)
		table.insert(self.__tasks, newTask)
	end
	local function destroy(self)
		for _, task in pairs(self.__tasks) do
			handleTask(task)
		end
		self.__tasks = {}
	end

	local methodAliases = {
		GiveTask = giveTask,
		giveTask = giveTask,
		Destroy = destroy,
		destroy = destroy,
		doCleaning = destroy,
		DoCleaning = destroy,
	}
	local mt = {
		__call = giveTask,
		__index = methodAliases,
	}

	function Maid()
		return setmetatable({
			__tasks = {},
		}, mt)
	end
end

-- public
return function(ScrollingFrame, Commands)
	--[[
		@param: ScrollingFrame
		@param: table Commands
			{ string commandName --> function(Console): nil }
		@return: Maid
	]]

	-- const
	local NUM_EXTRA_LINES = 6

	-- var
	local TerminalMaid = Maid()
	local ThreadMaid = Maid()
	local InputMaid = Maid()
	local TextBox

	local terminalIsRunning = false
	local exitFlag = false

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

		text = tostring(text)

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

		prompt = tostring(prompt)

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

		args = tostring(args)

		-- trim leading spaces
		local i = 1
		while i <= string.len(args) and string.sub(args, i, i) == " " do
			i += 1
		end
		args = string.sub(args, i, string.len(args))

		-- string --> table
		args = string.split(args, " ")
		local commandName = args[1]
		table.remove(args, 1)

		-- first arg is the name of the program
		-- if no program name, maybe it's a
		-- default Console function
		local s, msg
		if Commands[commandName] then
			s, msg = pcall(Commands[commandName], Console, table.unpack(args))
		elseif Console[commandName] then
			s, msg = pcall(Console[commandName], table.unpack(args))
		else
			if commandName ~= "" then
				return Console.output('\n"' .. commandName .. '" is not a command\n')
			end
			return
		end

		-- catch & output errors
		if not s then
			-- Console.exit() has to use an error() call to exit
			-- the current thread. this supports that implementation
			-- but doesn't output the unnecessary error message
			if exitFlag then
				exitFlag = false
				return
			end

			return Console.output("\n" .. msg .. "\n")
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
		task.spawn(function()
			if args then
				output(commandLineText .. args)
			end
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
	local function exit()
		--[[
			@post: quits all current programs and returns to command loop
		]]
		exitFlag = true -- this tells Console.command(...) not to output the error message
		error("Exited")
	end

	-- initialize the terminal
	TerminalMaid(ThreadMaid)

	TextBox = Instance.new("TextBox")
	TextBox.Size = UDim2.new(1, 0, 1, 0)
	TextBox.Font = Enum.Font.Code
	TextBox.ClearTextOnFocus = false
	TextBox.TextWrapped = true
	TextBox.TextXAlignment = Enum.TextXAlignment.Left
	TextBox.TextYAlignment = Enum.TextYAlignment.Top
	TextBox.Text = ""
	TextBox.Parent = ScrollingFrame
	TerminalMaid(TextBox)

	TextBox:GetPropertyChangedSignal("Text"):Connect(textChanged)
	TextBox:GetPropertyChangedSignal("CursorPosition"):Connect(cursorPositionChanged)

	-- return Console object for interacting with the terminal
	Console = {
		input = input,
		output = output,
		command = command,
		clear = clear,
		destroy = destroy,
		Destroy = destroy, -- in case someone uses Quenty's Maid implementation
		initialize = initialize,
		terminate = terminate,
		exit = exit,

		TextBox = TextBox,
	}
	return Console
end
