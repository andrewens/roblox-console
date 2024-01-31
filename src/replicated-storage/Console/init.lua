-- public
local function newConsole()
	-- var
	local TextBox = Instance.new("TextBox")
	local charactersPerLine = 16
	local text = "Welcome to `roblox-console`!"

	local CustomGetMethods = {} -- string customPropertyName --> function(): <any>
	local CustomSetMethods = {} -- string customPropertyName --> function(value): nil

	-- public
	local function isConsoleRBXInstance(self, AnyInstance)
		return TextBox == AnyInstance
	end
	local function getConsoleText(self)
		return text
	end
	local function setConsoleText(self, str)
		if not (typeof(str) == "string") then
			error(tostring(str) .. " isn't a string!")
		end
		text = str
	end
	local function addConsoleText(self, str)
		if not (typeof(str) == "string") then
			error(tostring(str) .. " isn't a string!")
		end
		text = text .. str
	end
	local function getTextLines(self, accountForTextWrapping)
		if accountForTextWrapping then
			local wrappedText = {} -- int --> string (words separated by spaces, no trailing space)
			local wrappedLine = ""

			for i, str in string.split(text, "\n") do
				local words = string.split(str, " ")
				for j, word in words do
					-- if the word fits, we just add it to the previous line
					local spaceNeeded = string.len(wrappedLine) > 0 -- the word needs a space if other words come before it
					local wordLength = string.len(word) + (if spaceNeeded then 1 else 0)
					if wordLength + string.len(wrappedLine) <= charactersPerLine then
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
					if wordLength <= charactersPerLine then
						wrappedLine = wrappedLine .. word
						continue
					end

					-- at this point the word is longer than charactersPerLine and we have to chop it up into sections
					for k = 0, math.ceil(string.len(word) / charactersPerLine) - 1 do
						wrappedLine = string.sub(word, (k * charactersPerLine) + 1, (k + 1) * charactersPerLine)
						if string.len(wrappedLine) >= charactersPerLine then
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
	local function getCharactersPerLine()
		return charactersPerLine
	end
	local function setCharactersPerLine(anyNumber)
		if not (typeof(anyNumber) == "number") then
			error(tostring(anyNumber) .. " is not a number!")
		end
		charactersPerLine = math.max(math.floor(anyNumber), 1) -- convert to natural number
	end

	-- public | metamethods
	local function __index(_, key)
		if CustomGetMethods[key] then
			return CustomGetMethods[key]()
		end
		return TextBox[key]
	end
	local function __newindex(_, key, value)
		if CustomSetMethods[key] then
			CustomSetMethods[key](value)
			return
		end
		TextBox[key] = value
	end

	-- init
	CustomGetMethods = {
		CharactersPerLine = getCharactersPerLine,
	}
	CustomSetMethods = {
		CharactersPerLine = setCharactersPerLine,
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

	return self
end

return {
	new = newConsole,
}
