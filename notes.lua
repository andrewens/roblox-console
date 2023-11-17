--[[
    Custom TextBox wrapping a TextLabel -- so I can add syntax highlighting

    Cursor i, j
    Buffer

    Move cursor
    Write text at cursor
    Read

    * TextLabel automatically wraps text
    * CustomTextBox automatically applies colors to keywords
    * CustomTextBox handles input
    * CustomTextBox controls cursor position
]]

local UserInputService = game:GetService("UserInputService")
local Maid

local function TextBuffer(str)
	local strBuffer = str or ""
	local cursorPosition = string.len(str)
	--[[
        local cursor_i = 1
        local cursor_j = 1
        
        -- init cursor
        local lastNewLineChar = 0
        for i = 1, string.len(str) do
            if string.sub(str, i, i) == "\n" then
                cursor_i += 1
                lastNewLineChar = i
            end
        end
        cursor_j = string.len(str) - lastNewLineChar -- inclusive
    --]]
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
	--[[
    local function cursorPosition(i, j)
        if i then
            assert(typeof(i) == "number")
        end
        if j then
            assert(typeof(j) == "number")
        end
        return cursor_i, cursor_j
    end--]]

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
	local TextBoxBuffer = TextBuffer(str)

	local TextLabel = Instance.new("TextLabel")
	TextLabel.Size = UDim2.new(1, 0, 1, -ScrollingFrame.ScrollBarThickness)
	TextLabel.TextXAlignment = Enum.TextXAlignment.Left
	TextLabel.TextYAlignment = Enum.TextYAlignment.Top
	TextLabel.TextWrapepd = true
	TextLabel.Text = TextBoxBuffer.buffer()
    TextLabel.RichText = true
	TextLabel.Parent = ScrollingFrame
	TextBoxMaid(TextLabel)

	ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, TextLabel.TextBounds.Y)

    local inputText
    if ColorCode then
        -- remap color code
        for color3, words in ColorCode do
            local r = tostring(math.round(color3.R * 255))
            local g = tostring(math.round(color3.G * 255))
            local b = tostring(math.round(color3.B * 255))
            local strColor3 = '<font color="rgb(' .. r .. "," .. g .. "," .. b .. ')">'
            for _, word in words do
                ColorCode[word] = strColor3 -- it's so inefficient... I'm sorry T_T
            end
            ColorCode[color3] = nil
        end

        -- apply color code when adding text
        function inputText(text)
            TextBuffer.addText(text)

            text = ""
            for line in string.split(TextBuffer.buffer(), "\n") do
                for word in string.split(line, " ") do
                    local color = ColorCode[word]
                    if color then
                        text = text .. color .. word .. "</font> "
                    else
                        text = text .. word .. " "
                    end
                end
                text = text .. "\n"
            end
            TextLabel.Text = TextBoxBuffer.buffer()
        end
    else
        function inputText(text)
            TextBuffer.addText(text)
            TextLabel.Text = TextBoxBuffer.buffer()
        end
    end

	-- A sample function providing one usage of InputBegan
	local function onInputBegan(input, _gameProcessed)
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.Enter then
                inputText("\n")
            else
                inputText(string.char(input.KeyCode))
            end
		end
	end
	TextBoxMaid(UserInputService.InputBegan:Connect(onInputBegan))

	return TextBoxMaid
end
