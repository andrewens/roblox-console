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
	local function getCharactersPerLine()
		return charactersPerLine
	end
	local function setCharactersPerLine(anyNumber)
		if not (typeof(anyNumber) == "number") then
			error(tostring(anyNumber) .. " is not a number!")
		end
		charactersPerLine = math.max(math.floor(anyNumber), 1) -- convert to natural number
	end
	local function getTextLines()
		return string.split(text, "\n")
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
