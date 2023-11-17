-- dependency
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local Maid = require(script:FindFirstChild("Maid"))
local ProxyTable = require(script:FindFirstChild("ProxyTable"))
local Loadstring = require(ReplicatedStorage:FindFirstChild("Loadstring"))
local RobloxCSS = require(ReplicatedStorage:FindFirstChild("roblox-css"))

local LocalPlayer = Players.LocalPlayer

-- default program source
local helloWorldProgram = [[
-- command line applications take Console as first arg, then all args passed from command line

return function(Console, ...)

	Console.output("Hi mom! " .. table.concat({...}, " "))

end]]
local addTwoNumsProgram = [[
-- command line applications take Console as first arg, then all args passed from command line

return function(Console, a, b, ...)

	a = tonumber(a)
	b = tonumber(b)
	Console.output(a + b)

end]]
local stylesheetDemo = [[
-- if your file name ends in ".rcss", it will be interpreted as a stylesheet

return function(RBXClass, CustomClass, CustomProperty)

	RBXClass.Frame {
		BorderSizePixel = 0,
		BackgroundColor3 = "black",
	}
	RBXClass.ScrollingFrame {
		BorderSizePixel = 0,
		BackgroundColor3 = "black",
		ScrollBarThickness = 8,
	}

	local TextStyle = {
		TextColor3 = "white",
		BackgroundColor3 = "black",
		BorderSizePixel = 0,
		TextXAlignment = Enum.TextXAlignment.Left
	}
	RBXClass.TextLabel(TextStyle)
	RBXClass.TextBox(TextStyle)
	RBXClass.TextButton(TextStyle)

	-- these custom classes are defined in the actual source code for this editor
	-- using something like MyTextLabel:SetAttribute("class", "FileName")

	CustomClass.FileName {
		TextColor3 = "white"
	}
	CustomClass.EditorToggle {
		TextColor3 = "white",
		TextXAlignment = Enum.TextXAlignment.Center,
	}
	CustomClass.ConsoleText {
		TextColor3 = "green",
	}
	CustomClass.FileEditor {
		TextColor3 = "orange",
	}

	-- CustomProperties allow us to define Color3's in terms of strings

	local COLOR_PALETTE = {
		white = Color3.new(1, 1, 1),
		black = Color3.new(0.1, 0.1, 0.1),
		green = Color3.new(0, 1, 0),
		orange = Color3.new(1, 0.5, 0),
	}
	local function customColor3(RBXInstance, property, value)
		RBXInstance[property] = COLOR_PALETTE[value] or value
	end
	CustomProperty.BackgroundColor3(customColor3)
	CustomProperty.TextColor3(customColor3)
end
]]
local paddingStylesheet = [[
return function(RBX, Custom, Property)

	RBX.Frame {
		Padding = 5
	}
	RBX.ScrollingFrame {
		PaddingRight = 15, -- for scroll bar
	}

	local function customPadding(Inst, property, value)
		local Padding = Inst:FindFirstChildWhichIsA("UIPadding")
		if Padding == nil then
			Padding = Instance.new("UIPadding")
			Padding.Parent = Inst
		end

		if property == "Padding" then
			Padding.PaddingLeft = UDim.new(0, value)
			Padding.PaddingRight = UDim.new(0, value)
			Padding.PaddingBottom = UDim.new(0, value)
			Padding.PaddingTop = UDim.new(0, value)
			return
		end

		Padding[property] = UDim.new(0, value)
	end

	Property.Padding(customPadding)
	Property.PaddingLeft(customPadding)
	Property.PaddingRight(customPadding)
	Property.PaddingTop(customPadding)
	Property.PaddingBottom(customPadding)

end
]]

-- state
local function file(fileName, text)
	return ProxyTable({
		Name = fileName,
		Source = text,
	})
end
local AppState = ProxyTable({
	Files = ProxyTable({
		file("hello-world", helloWorldProgram),
		file("add", addTwoNumsProgram),
		file("stylesheet-demo.rcss", stylesheetDemo),
		file("padding.rcss", paddingStylesheet),
	}),
	SelectedFile = 1,
})

local function getSelectedFile()
	return AppState.Files[AppState.SelectedFile]
end
local function selectFile(fileIndex)
	assert(typeof(fileIndex) == "number")
	AppState.SelectedFile = fileIndex
end
local function newFile()
	AppState.Files[#AppState.Files + 1] = file("NewFile", "return function()\n\tprint('hello world')\nend\n")
end

-- gui objects
local function TextBuffer(str)
	--[[
		Data structure to manage cursor position while editing a big block of text
		@param: string? str
	]]
	local strBuffer = str or ""
	local cursorPosition = string.len(strBuffer)

	-- public
	local function addText(newText)
		strBuffer = string.sub(strBuffer, 1, cursorPosition) .. newText .. string.sub(strBuffer, cursorPosition + 1, -1)
		cursorPosition += string.len(newText)
	end
	local function buffer(newStr)
		if newStr then
			strBuffer = newStr
			cursorPosition = math.min(string.len(newStr), cursorPosition)
		end
		return strBuffer
	end
	local function countLines()
		local numLines = 0
		for _ in string.gmatch(strBuffer, "\n") do
			numLines += 1
		end
		return numLines
	end

	return {
		addText = addText,
		buffer = buffer,
		countLines = countLines,
	}
end
local function TextBox(ScrollingFrame, str, ColorCode)
    --[[
        @param: ScrollingFrame
        @param: string? str
        @param: table ColorCode
            { [Color3] --> { string word } }
    ]]
	local TextBoxMaid = Maid()
	local TextBoxBuffer = TextBuffer()

	local TextLabel = Instance.new("TextLabel")
	TextLabel.Size = UDim2.new(1, 0, 1, -ScrollingFrame.ScrollBarThickness)
	TextLabel.TextXAlignment = Enum.TextXAlignment.Left
	TextLabel.TextYAlignment = Enum.TextYAlignment.Top
	TextLabel.TextWrapped = true
	TextLabel.Text = TextBoxBuffer.buffer()
    TextLabel.RichText = true
	TextLabel.Parent = ScrollingFrame
	TextBoxMaid(TextLabel)

	ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, TextLabel.TextBounds.Y)

    local inputText
    if ColorCode then
        -- remap color code
		local RichTextColors = {}
        for color3, words in ColorCode do
			print("COLOR#", color3, typeof(color3))
            local r = tostring(math.round(color3.R * 255))
            local g = tostring(math.round(color3.G * 255))
            local b = tostring(math.round(color3.B * 255))
            local strColor3 = '<font color="rgb(' .. r .. "," .. g .. "," .. b .. ')">'
            for _, word in words do
                RichTextColors[word] = strColor3 -- it's so inefficient... I'm sorry T_T
            end
        end

        -- apply color code when adding text
        function inputText(text)
            TextBoxBuffer.addText(text)

            text = ""
            for _, line in string.split(TextBoxBuffer.buffer(), "\n") do
                for _, word in string.split(line, " ") do
                    local color = RichTextColors[word]
                    if color then
                        text = text .. color .. word .. "</font> "
                    else
                        text = text .. word .. " "
                    end
                end
                text = text .. "\n"
            end
            TextLabel.Text = text
        end
    else
        function inputText(text)
            TextBoxBuffer.addText(text)
            TextLabel.Text = TextBoxBuffer.buffer()
        end
    end
	inputText(str)

	-- A sample function providing one usage of InputBegan
	local function onInputBegan(input, _gameProcessed)
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.Return then
                inputText("\n")
            else
                inputText(string.char(input.KeyCode.Value))
            end
		end
	end
	TextBoxMaid(UserInputService.InputBegan:Connect(onInputBegan))

	return TextBoxMaid
end

local function console(Frame, updateStyleSheets)
	local ConsoleMaid = Maid()

	local ConsoleInterface

	local PROGRAM_DESC = {
		clear = " -- Clears all text from console",
		save = " -- Compiles program files & updates GUI style",
		help = " -- Lists all programs",
	}

	local Programs = {}
	local StyleSheets = {}
	local function updatePrograms()
		Programs = {
			clear = function(CLI)
				CLI.clear()
			end,
			save = updatePrograms,
			help = function(CLI)
				for programName, _ in Programs do
					CLI.output(programName .. (PROGRAM_DESC[programName] or ""))
				end
			end,
		}
		StyleSheets = {}
		for i, File in AppState.Files do
			-- can't have two programs with the same name
			if Programs[File.Name] then
				ConsoleInterface.output('Attempt to define program "' .. File.Name .. '" multiple times')
				continue
			end

			-- use Loadstring to turn the File.Source (string) into a real Lua function
			local compileProgram, failMessage = Loadstring(File.Source)
			if failMessage then
				ConsoleInterface.output("Error while compiling " .. File.Name .. ": " .. tostring(failMessage))
				continue
			end

			-- kinda meta, but the function has to return a function which is the actual command line program or rcss stylesheet
			local s, program = pcall(compileProgram)
			if not s then
				ConsoleInterface.output("Error while compiling " .. File.Name .. ": " .. tostring(program))
				continue
			end
			if typeof(program) ~= "function" then
				ConsoleInterface.output("File " .. File.Name .. " failed to return a function")
				continue
			end

			-- if file name ends in .rcss, it's a stylesheet
			if string.sub(File.Name, string.len(File.Name) - 4, -1) == ".rcss" then
				table.insert(StyleSheets, program)
				continue
			end

			-- normal command line program
			Programs[File.Name] = program
		end

		updateStyleSheets(StyleSheets)
	end

	local LINE_HEIGHT = 20
	local FONT = Enum.Font.Code
	local START_OF_LINE_SYMBOL = LocalPlayer.Name .. " > "
	local START_OF_LINE_SYMBOL_LEN = string.len(START_OF_LINE_SYMBOL)
	local SCROLLBAR_WIDTH = 10
	local COMMAND_SEPARATOR_START_OF_LINE_SYMBOL = " "

	local function getTextSize(str)
		return TextService:GetTextSize(str, 12, FONT, Frame.AbsoluteSize - Vector2.new(SCROLLBAR_WIDTH, 0))
	end

	local ScrollingFrame = Instance.new("ScrollingFrame")
	ScrollingFrame.Size = UDim2.new(1, 0, 1, 0)
	ScrollingFrame.ScrollBarThickness = SCROLLBAR_WIDTH
	ScrollingFrame.Parent = Frame
	ConsoleMaid(ScrollingFrame)

	local ListLayout = Instance.new("UIListLayout")
	ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ListLayout.Parent = ScrollingFrame

	local buffer = {
		'Welcome to the `roblox-console` demo. Type "help" to see a list of commands.',
	}

	local BufferMaid = Maid()

	local function drawOutput(i)
		local str = START_OF_LINE_SYMBOL .. buffer[i]
		assert(str)
		local size = getTextSize(str)

		local TextLabel = Instance.new("TextLabel")
		TextLabel.Size = UDim2.new(0, size.X, 0, size.Y + 0.5 * LINE_HEIGHT)
		TextLabel.Text = str
		TextLabel.LayoutOrder = i
		TextLabel.TextYAlignment = Enum.TextYAlignment.Top
		TextLabel.TextXAlignment = Enum.TextXAlignment.Left
		TextLabel.TextWrapped = true
		TextLabel:SetAttribute("class", "ConsoleText")
		TextLabel.Parent = ScrollingFrame

		BufferMaid(TextLabel)
	end
	local function redrawBuffer()
		BufferMaid:DoCleaning()

		for i, str in buffer do
			drawOutput(i)
		end
	end
	local function newOutput(str)
		local i = #buffer + 1
		table.insert(buffer, str)

		drawOutput(i)
	end

	local CommandLine = Instance.new("TextBox")
	CommandLine.Size = UDim2.new(1, 0, 0, LINE_HEIGHT)
	CommandLine.TextXAlignment = Enum.TextXAlignment.Left
	CommandLine.TextYAlignment = Enum.TextYAlignment.Top
	CommandLine.LayoutOrder = 100000
	CommandLine.ClearTextOnFocus = false
	CommandLine.Text = START_OF_LINE_SYMBOL
	CommandLine:SetAttribute("class", "ConsoleText")
	CommandLine.Parent = ScrollingFrame

	local commandInput = ""
	CommandLine:GetPropertyChangedSignal("Text"):Connect(function()
		-- disallow deleting the start of line START_OF_LINE_SYMBOL
		if string.sub(CommandLine.Text, 1, START_OF_LINE_SYMBOL_LEN) ~= START_OF_LINE_SYMBOL then
			CommandLine.Text = START_OF_LINE_SYMBOL .. commandInput
			return
		end

		commandInput = string.sub(CommandLine.Text, 1 + START_OF_LINE_SYMBOL_LEN, -1)
	end)
	CommandLine:GetPropertyChangedSignal("CursorPosition"):Connect(function()
		-- disallow moving cursor into start of line START_OF_LINE_SYMBOL
		if CommandLine.CursorPosition < START_OF_LINE_SYMBOL_LEN + 1 then
			CommandLine.CursorPosition = START_OF_LINE_SYMBOL_LEN + 1
		end
	end)

	ConsoleInterface = {
		output = newOutput,
		clear = function()
			buffer = {}
			redrawBuffer()
		end,
	}
	local function onFocusLost(enterPressed, inputThatCausedFocusLost)
		if not enterPressed then
			return
		end

		-- sanitize input to ignore disgusting control characters
		commandInput = string.gsub(commandInput, "%c", "")

		-- save the input to buffer
		newOutput(commandInput)

		-- run a program
		local args = string.split(commandInput, COMMAND_SEPARATOR_START_OF_LINE_SYMBOL)
		local selectedProgram = Programs[args[1]]
		if selectedProgram then
			table.remove(args, 1)
			local s, msg = pcall(selectedProgram, ConsoleInterface, table.unpack(args))
			if not s then
				newOutput("Error: " .. tostring(msg))
			end
		elseif args[1] ~= "" then
			newOutput('"' .. args[1] .. '" is not a command')
		end

		-- refresh command input line
		commandInput = ""
		CommandLine.Text = START_OF_LINE_SYMBOL
		CommandLine:CaptureFocus()
	end
	CommandLine.FocusLost:Connect(onFocusLost)

	redrawBuffer()
	updatePrograms()

	return ConsoleMaid
end
local function textEditor(Frame)
	local EditorMaid = Maid()

	local FILE_NAME_HEIGHT = 50

	-- input a different file name
	local FileName = Instance.new("TextBox")
	FileName.Size = UDim2.new(1, 0, 0, FILE_NAME_HEIGHT)
	FileName.ClearTextOnFocus = false
	FileName.TextXAlignment = Enum.TextXAlignment.Left
	FileName:SetAttribute("class", "FileName")
	FileName.Parent = Frame
	EditorMaid(FileName)

	local function setFileName()
		local File = getSelectedFile()
		File.Name = FileName.ContentText
	end
	FileName.FocusLost:Connect(setFileName)
	FileName.ReturnPressedFromOnScreenKeyboard:Connect(setFileName)

	-- edit the file
	local ScrollingFrame = Instance.new("ScrollingFrame")
	ScrollingFrame.Position = UDim2.new(0, 0, 0, FILE_NAME_HEIGHT)
	ScrollingFrame.Size = UDim2.new(1, 0, 1, -FILE_NAME_HEIGHT)
	ScrollingFrame.Parent = Frame
	EditorMaid(ScrollingFrame)

	local FileEditor = Instance.new("TextBox")
	FileEditor.ClearTextOnFocus = false
	FileEditor.MultiLine = true
	FileEditor.TextXAlignment = Enum.TextXAlignment.Left
	FileEditor.TextYAlignment = Enum.TextYAlignment.Top
	FileEditor.TextWrapped = true
	FileEditor:SetAttribute("class", "FileEditor")
	FileEditor.Parent = ScrollingFrame
	EditorMaid(FileEditor)

	local function updateCanvasSize()
		-- TextService is rubbish :/
		--local textSize =
		--	TextService:GetTextSize(FileEditor.Text, FileEditor.TextSize, FileEditor.Font, FileEditor.AbsoluteSize)

		local textSizeY = string.len(FileEditor.Text)
		FileEditor.Size = UDim2.new(1, 0, 0, textSizeY + 50)
		ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, textSizeY + 50)
	end
	FileEditor:GetPropertyChangedSignal("Text"):Connect(updateCanvasSize)

	local function setFileSource()
		local File = getSelectedFile()
		File.Source = FileEditor.ContentText
	end
	FileEditor.FocusLost:Connect(setFileSource)

	-- change which file we're editing when the selection changes
	EditorMaid(AppState:changed("SelectedFile", function(...)
		local File = getSelectedFile()
		FileName.Text = File.Name
		FileEditor.Text = File.Source
	end))

	updateCanvasSize()

	return EditorMaid
end
local function fileBrowser(Frame)
	local BrowserMaid = Maid()

	local FILE_BUTTON_HEIGHT = 30
	local NEW_FILE_BUTTON_HEIGHT = 50

	local NewFile = Instance.new("TextButton")
	NewFile.Size = UDim2.new(1, 0, 0, NEW_FILE_BUTTON_HEIGHT)
	NewFile.Text = "NEW FILE [+]"
	NewFile.Activated:Connect(newFile)
	NewFile:SetAttribute("class", "FileName")
	NewFile.Parent = Frame

	local Container = Instance.new("ScrollingFrame")
	Container.Position = UDim2.new(0, 0, 0, NEW_FILE_BUTTON_HEIGHT)
	Container.Size = UDim2.new(1, 0, 1, -NEW_FILE_BUTTON_HEIGHT)
	Container.Parent = Frame
	BrowserMaid(Container)

	local UpdateMaid = Maid()
	local function updateBrowser()
		UpdateMaid:DoCleaning()

		Container.CanvasSize = UDim2.new(0, 0, 0, #AppState.Files * FILE_BUTTON_HEIGHT)
		for i, File in AppState.Files do
			local FileButton = Instance.new("TextButton")
			FileButton.Position = UDim2.new(0, 0, 0, (i - 1) * FILE_BUTTON_HEIGHT)
			FileButton.Size = UDim2.new(1, 0, 0, FILE_BUTTON_HEIGHT)
			FileButton:SetAttribute("class", "FileName")
			FileButton.Parent = Container
			UpdateMaid(File:changed("Name", function(_, newName)
				FileButton.Name = newName
				FileButton.Text = newName
			end))
			UpdateMaid(FileButton.Activated:Connect(function()
				selectFile(i)
			end))
			UpdateMaid(FileButton)
		end
	end

	BrowserMaid(AppState.Files:changed(updateBrowser))

	return BrowserMaid
end
local function guiMain(Parent)
	local GuiMaid = Maid()

	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

	local ScreenGui

	-- top bar screen gui (enables/disables editor)
	local TopBarGui = Instance.new("ScreenGui")
	TopBarGui.IgnoreGuiInset = true
	TopBarGui.Parent = Parent
	GuiMaid(TopBarGui)

	local ToggleButton = Instance.new("TextButton")
	ToggleButton.Size = UDim2.new(1, 0, 0, 50)
	ToggleButton:SetAttribute("class", "EditorToggle")
	ToggleButton.Parent = TopBarGui

	local function toggle()
		ScreenGui.Enabled = not ScreenGui.Enabled
		ToggleButton.Text = if ScreenGui.Enabled then "HIDE EDITOR" else "SHOW EDITOR"
	end
	ToggleButton.Activated:Connect(toggle)

	-- IDE screen gui
	ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Parent = Parent
	GuiMaid(ScreenGui)

	ScreenGui.Enabled = false
	toggle()

	local StyleMaid = Maid()
	local function updateStyleSheets(NewStyleSheets)
		StyleMaid:DoCleaning()
		local dismountHandle = RobloxCSS.mount(ScreenGui, NewStyleSheets)
		local dismountHandle2 = RobloxCSS.mount(TopBarGui, NewStyleSheets)
		StyleMaid:GiveTask(function()
			RobloxCSS.dismount(dismountHandle)
			RobloxCSS.dismount(dismountHandle2)
		end)
	end

	local Console = Instance.new("Frame")
	Console.Size = UDim2.new(0.4, 0, 1, 0)
	Console.Parent = ScreenGui
	GuiMaid(console(Console, updateStyleSheets))

	local TextEditor = Instance.new("Frame")
	TextEditor.Position = UDim2.new(0.4, 0, 0, 0)
	TextEditor.Size = UDim2.new(0.4, 0, 1, 0)
	TextEditor.Parent = ScreenGui
	GuiMaid(textEditor(TextEditor))

	local Browser = Instance.new("Frame")
	Browser.Position = UDim2.new(0.8, 0, 0, 0)
	Browser.Size = UDim2.new(0.2, 0, 1, 0)
	Browser.Parent = ScreenGui
	GuiMaid(fileBrowser(Browser))

	-- TEST TEST TEST TEST --
	local ScrollingFrame = Instance.new("ScrollingFrame")
	ScrollingFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	ScrollingFrame.Size = UDim2.new(0, 400, 0, 400)
	ScrollingFrame.Parent = ScreenGui
	GuiMaid(TextBox(ScrollingFrame, "test\ntest\ntest", {
		[Color3.new(1, 0, 0)] = {
			"test"
		}
	}))

	return GuiMaid
end



guiMain(LocalPlayer.PlayerGui)
