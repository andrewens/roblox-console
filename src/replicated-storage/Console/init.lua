-- public
local function newConsole()
	-- var
	local ConsoleContainerInstance = Instance.new("Frame")
	local maxCharsPerLine = 16
	local text = "Welcome to `roblox-console`!"

	local CustomGetMethods = {} -- string customPropertyName --> function(): <any>
	local CustomSetMethods = {} -- string customPropertyName --> function(value): nil

	local RenderedTextLabels = {} -- i --> TextLabel

	local getTextLines -- public method

	-- private
	local function updateTextRender(self)
		-- create new text labels
		local NewRenderedTextLabels = {}
		for i, textLine in getTextLines(self, true) do
			local TextLabel = RenderedTextLabels[i]
			if TextLabel == nil then
				TextLabel = Instance.new("TextLabel")
				TextLabel.Name = "Line" .. tostring(i)
				TextLabel.Parent = ConsoleContainerInstance
			end
			RenderedTextLabels[i] = nil
			NewRenderedTextLabels[i] = TextLabel
			TextLabel.Text = textLine
		end

		-- cleanup
		for i, TextLabel in RenderedTextLabels do
			TextLabel:Destroy()
		end
		RenderedTextLabels = NewRenderedTextLabels
	end

	-- public
	local function isConsoleRBXInstance(self, AnyInstance)
		return ConsoleContainerInstance == AnyInstance
	end
	local function getConsoleText(self)
		return text
	end
	local function setConsoleText(self, str)
		if not (typeof(str) == "string") then
			error(tostring(str) .. " isn't a string!")
		end
		text = str
		updateTextRender(self)
	end
	local function addConsoleText(self, str)
		if not (typeof(str) == "string") then
			error(tostring(str) .. " isn't a string!")
		end
		text = text .. str
		updateTextRender(self)
	end
	function getTextLines(self, accountForTextWrapping)
		if accountForTextWrapping then
			local wrappedText = {} -- int --> string (words separated by spaces, no trailing space)
			local wrappedLine = ""

			for i, str in string.split(text, "\n") do
				local words = string.split(str, " ")
				for j, word in words do
					-- if the word fits, we just add it to the previous line
					local spaceNeeded = string.len(wrappedLine) > 0 -- the word needs a space if other words come before it
					local wordLength = string.len(word) + (if spaceNeeded then 1 else 0)
					if wordLength + string.len(wrappedLine) <= maxCharsPerLine then
						if spaceNeeded then
							wrappedLine = wrappedLine .. " "
						end
						wrappedLine = wrappedLine .. word
						continue
					end

					-- new line if the word didn't fit
					table.insert(wrappedText, wrappedLine)
					wrappedLine = ""

					-- does the word fit now? (no spaces are required b/c it's a fresh new line)
					wordLength = string.len(word)
					if wordLength <= maxCharsPerLine then
						wrappedLine = wrappedLine .. word
						continue
					end

					-- at this point the word is longer than maxCharsPerLine and we have to chop it up into sections
					for k = 0, math.ceil(string.len(word) / maxCharsPerLine) - 1 do
						wrappedLine = string.sub(word, (k * maxCharsPerLine) + 1, (k + 1) * maxCharsPerLine)
						if string.len(wrappedLine) >= maxCharsPerLine then
							table.insert(wrappedText, wrappedLine)
							wrappedLine = "" -- i'm not sure if this is necessary but i'm paranoid of a tiny edge case
						end
					end
				end

				table.insert(wrappedText, wrappedLine)
				wrappedLine = ""
			end

			return wrappedText
		end
		return string.split(text, "\n")
	end
	local function getMaxCharsPerLine(self)
		return maxCharsPerLine
	end
	local function setMaxCharsPerLine(self, anyNumber)
		if not (typeof(anyNumber) == "number") then
			error(tostring(anyNumber) .. " is not a number!")
		end
		maxCharsPerLine = math.max(math.floor(anyNumber), 1) -- convert to natural number
		updateTextRender()
	end

	-- public | metamethods
	local function __index(self, key)
		if CustomGetMethods[key] then
			return CustomGetMethods[key](self)
		end
		return ConsoleContainerInstance[key]
	end
	local function __newindex(self, key, value)
		if CustomSetMethods[key] then
			CustomSetMethods[key](self, value)
			return
		end
		ConsoleContainerInstance[key] = value
	end

	-- init
	CustomGetMethods = {
		MaxCharactersPerLine = getMaxCharsPerLine,
	}
	CustomSetMethods = {
		MaxCharactersPerLine = setMaxCharsPerLine,
	}
	local mt = {
		__index = __index,
		__newindex = __newindex,
	}
	local self = {
		IsInstance = isConsoleRBXInstance,
		GetText = getConsoleText,
		SetText = setConsoleText,
		AddText = addConsoleText,
		GetLines = getTextLines,
	}
	setmetatable(self, mt)

	updateTextRender()

	return self
end

return {
	new = newConsole,
}
