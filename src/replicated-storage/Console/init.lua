-- public
local function newConsole()
	-- var
	local TextBox = Instance.new("TextBox")
	local charactersPerLine = 16

	local CustomGetMethods = {} -- string customPropertyName --> function(): <any>
	local CustomSetMethods = {} -- string customPropertyName --> function(value): nil

	-- public
	local function isConsoleRBXInstance(self, AnyInstance)
		return TextBox == AnyInstance
	end
	local function getCharactersPerLine()
		return charactersPerLine
	end
	local function setCharactersPerLine(anyNaturalNumber)
		if not (typeof(anyNaturalNumber) == "number") then
			error(tostring(anyNaturalNumber) .. " is not a number!")
		end
		charactersPerLine = math.max(math.floor(anyNaturalNumber), 1)
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
	}
	setmetatable(self, mt)

	return self
end

return {
	new = newConsole,
}
