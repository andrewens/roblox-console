local function TextBuffer()
    -- private | variables
	local maxCharsPerLine = 16 -- strings can't be longer than this number
	local buffer = {} -- i --> string

    -- public | metatable
	local function __iter(self)
		return next, buffer
	end
    local function __index(self, key)
        return buffer[key]
    end
    local function __tostring(self)
        return table.concat(buffer, "\n")
    end
    local function __eq(a, b)
        -- this only works as a metamethod if both a and b are TextBuffers
        return tostring(a) == tostring(b)
    end
    local function __len(self)
        return #buffer
    end

    -- public
    local function charsPerLine(newCharsPerLine)
        if newCharsPerLine then
            assert(typeof(newCharsPerLine) == "number")
            maxCharsPerLine = newCharsPerLine
        end
        return maxCharsPerLine
    end
	local function addText(str)
		assert(typeof(str) == "string")

		local i = #buffer
        local j = 1
        if i == 0 then
            i = 1
        else
            j = string.len(buffer[i]) + 1
        end
        
        local k = 1
        local str_len = string.len(str)
        while k <= str_len do
            local availableChars = maxCharsPerLine - j

            buffer[i] = (buffer[i] or "") .. string.sub(str, k, k + availableChars)
            i += 1
            j = 1
            k += availableChars + 1
        end
	end
    local function isEqual(str)
        -- you could think of this is as __tostring(self)
        -- but "self" isn't necessary because everything is local
        return __tostring() == str
    end
	local function deleteChars(numChars) end
	local function deleteLines(numLines) end

	local self = {
        charsPerLine = charsPerLine,
		addText = addText,
		deleteChars = deleteChars,
		deleteLines = deleteLines,
        isEqual = isEqual
	}
    local mt = {
		__iter = __iter,
        __index = __index,
        __tostring = __tostring,
        __eq = __eq,
        __len = __len,
	}

	return setmetatable(self, mt)
end
return TextBuffer
