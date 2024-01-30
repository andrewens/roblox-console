-- public
local function newConsole()
	-- var
	local TextBox = Instance.new("TextBox")

	-- public
	local function isConsoleRBXInstance(self, AnyInstance)
		return TextBox == AnyInstance
	end

	-- init
	local mt = {
		__index = function(_, key)
			return TextBox[key]
		end,
		__newindex = function(_, key, value)
			TextBox[key] = value
		end,
		__eq = function(_, value)
			return TextBox == value
		end
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
