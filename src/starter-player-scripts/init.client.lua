-- dependency
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Maid = require(script:FindFirstChild("Maid"))
local ProxyTable = require(script:FindFirstChild("ProxyTable"))
local Loadstring = require(ReplicatedStorage:FindFirstChild("Loadstring"))
local RobloxCSS = require(ReplicatedStorage:FindFirstChild("roblox-css"))
local Terminal = require(ReplicatedStorage:FindFirstChild("roblox-console"))

local LocalPlayer = Players.LocalPlayer

-- default program source
local readMeProgram = [[
return function(Console, ...)
	-- the terminal/command line is
	-- the green text on the left.

	-- type 'save' or 'compile' to
	-- compile these program files
	-- in the terminal.

	-- type a file name in the terminal
	-- to run it. files must return a
	-- function which takes the Console
	-- as the first parameter, and the
	-- terminal arguments (separated by
	-- spaces) as the rest of the
	-- parameters.

	-- to output all command line args
	-- to the terminal, do:

	Console.output(...)

	-- to get user input from the terminal
	-- (which yields) do

	local userInput = Console.input("Type some stuff & press enter")

	-- userinput will be a string, and you
	-- can output it back to the Console:

	Console.output(userInput)

	-- you can edit the file name at the
	-- top of this editor. If your file 
	-- name ends with ".rcss", it will be
	-- interpreted as a Roblox CSS
	-- stylesheet and applied to this 
	-- editor GUI. You can see the existing
	-- styles in all of the existing .rcss
	-- files in the file explorer to the
	-- right.
end
]]
local helloWorldProgram = [[
-- to run this program,
-- type "hello-world" in the terminal
-- (no quotes) and press enter

return function(Console, ...)
	Console.output("\nHi mom!")
end]]
local inputProgram = [[
return function(Console, ...)
	local name = Console.input("\nWhat is your name? ")
	Console.output("\nNice to meet you, " .. name)
end
]]
local addTwoNumsProgram = [[
return function(Console, a, b, ...)
	a = tonumber(a)
	b = tonumber(b)
	Console.output("\n" .. tostring(a + b))
end]]
local frameStylesheet = [[
	-- if your file name ends in ".rcss", 
	-- it will be interpreted as a stylesheet

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
	end
]]
local textStylesheet = [[
return function(RBXClass, CustomClass, CustomProperty)

	local TextStyle = {
		TextColor3 = "white",
		BackgroundColor3 = "black",
		BorderSizePixel = 0,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = 16,
		Font = Enum.Font.Code,
	}
	RBXClass.TextLabel(TextStyle)
	RBXClass.TextBox(TextStyle)
	RBXClass.TextButton(TextStyle)

	-- custom classes are applied using Attributes
	-- e.g. MyTextLabel:SetAttribute("class", "CustomClassName")

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
end
]]
local customColorsStylesheet = [[
-- CustomProperties allow us to define Color3's in terms of strings
return function(RBX, Custom, Property)
	local COLOR_PALETTE = {
		white = Color3.new(1, 1, 1),
		black = Color3.new(0.1, 0.1, 0.1),
		green = Color3.new(0, 1, 0),
		orange = Color3.new(1, 0.5, 0),
	}
	local function customColor3(RBXInstance, property, value)
		RBXInstance[property] = COLOR_PALETTE[value] or value
	end
	Property.BackgroundColor3(customColor3)
	Property.TextColor3(customColor3)
end
]]
local paddingStylesheet = [[
return function(RBX, Custom, Property)

	RBX.Frame {
		Padding = 5
	}
	RBX.ScrollingFrame {
		PaddingRight = 15, -- allow space for scroll bar
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

-- variables
local CompileMaid = Maid()
local EditorGui
local ToggleButtonGui
local TerminalFrame

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
		file("input-test", inputProgram),
		file("add", addTwoNumsProgram),
		file("READ_ME", readMeProgram),
		file("frames.rcss", frameStylesheet),
		file("text.rcss", textStylesheet),
		file("colorNames.rcss", customColorsStylesheet),
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
local function compilePrograms(Console)
	CompileMaid:DoCleaning()

	local Programs = {
		compile = compilePrograms,
		save = compilePrograms,
		update = compilePrograms,
	}
	local StyleSheets = {}
	for i, File in AppState.Files do
		-- can't have two programs with the same name
		if Programs[File.Name] then
			Console.output('\nAttempt to define program "' .. File.Name .. '" multiple times')
			continue
		end

		-- use Loadstring to turn the File.Source (string) into a real Lua function
		local compileProgram, failMessage = Loadstring(File.Source)
		if failMessage then
			Console.output("\nError while compiling " .. File.Name .. ": " .. tostring(failMessage))
			continue
		end

		-- kinda meta, but the function has to return a function which is the actual command line program or rcss stylesheet
		local s, program = pcall(compileProgram)
		if not s then
			Console.output("\nError while compiling " .. File.Name .. ": " .. tostring(program))
			continue
		end
		if typeof(program) ~= "function" then
			Console.output("\nFile " .. File.Name .. " failed to return a function")
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

	-- update the terminal
	CompileMaid(Terminal(TerminalFrame, Programs))

	-- update the stylesheets
	local dismountHandle = RobloxCSS.mount(EditorGui, StyleSheets)
	local dismountHandle2 = RobloxCSS.mount(ToggleButtonGui, StyleSheets)
	CompileMaid(function()
		RobloxCSS.dismount(dismountHandle)
		RobloxCSS.dismount(dismountHandle2)
	end)
end

-- gui objects
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

	-- top bar screen gui (enables/disables editor)
	ToggleButtonGui = Instance.new("ScreenGui")
	ToggleButtonGui.IgnoreGuiInset = true
	ToggleButtonGui.Parent = Parent
	GuiMaid(ToggleButtonGui)

	local ToggleButton = Instance.new("TextButton")
	ToggleButton.Size = UDim2.new(1, 0, 0, 50)
	ToggleButton:SetAttribute("class", "EditorToggle")
	ToggleButton.Parent = ToggleButtonGui

	local function toggle()
		EditorGui.Enabled = not EditorGui.Enabled
		ToggleButton.Text = if EditorGui.Enabled then "HIDE EDITOR" else "SHOW EDITOR"
	end
	ToggleButton.Activated:Connect(toggle)

	-- IDE screen gui
	EditorGui = Instance.new("ScreenGui")
	EditorGui.Parent = Parent
	GuiMaid(EditorGui)

	EditorGui.Enabled = false
	toggle()

	TerminalFrame = Instance.new("ScrollingFrame")
	TerminalFrame.Size = UDim2.new(0.4, 0, 1, 0)
	TerminalFrame.Parent = EditorGui

	local TextEditor = Instance.new("Frame")
	TextEditor.Position = UDim2.new(0.4, 0, 0, 0)
	TextEditor.Size = UDim2.new(0.4, 0, 1, 0)
	TextEditor.Parent = EditorGui
	GuiMaid(textEditor(TextEditor))

	local Browser = Instance.new("Frame")
	Browser.Position = UDim2.new(0.8, 0, 0, 0)
	Browser.Size = UDim2.new(0.2, 0, 1, 0)
	Browser.Parent = EditorGui
	GuiMaid(fileBrowser(Browser))

	-- init
	compilePrograms({
		input = error,
		output = warn,
	})

	return GuiMaid
end

guiMain(LocalPlayer.PlayerGui)
