--[[
	A ProxyTable wraps a normal Lua table such that you can detect when
	the table is written to. This implementation allows you to subscribe
	callback functions to happen when a specific key/value pair is changed
	or any key/value pair is changed.

	I find this to be a lighter alternative to state management than something
	like Redux.

	Note that ProxyTables are shallow and only detect changes on one layer. If
	you set a value of a ProxyTable to be another table, the original ProxyTable
	won't detect changes to that table -- you must instead create more ProxyTables.

	** The __iter metamethod only works with Luau, the ROBLOX fork of Lua! You 
    	will have to modify that part for use with vanilla Lua.

	Andrew Ens
	October 2023
  
  	View this gist and more on my github:
		https://gist.github.com/andrewens/
--]]
--[[
	Usage:

	1. Initialize a new ProxyTable

		local ProxyTable = require(...)
		local MyTable = ProxyTable({ ... })

	2. Connect/disconnect callback for a specific key

		-- connect a function to be called when value at "ASpecificKey" is changed
		-- if MyTable["ASpecificKey"] isn't nil, the callback will be invoked immediately
		-- upon connection
		local disconnect = MyTable:changed("ASpecificKey", function(key, newValue)
			print(key, newValue)
		end

		-- this will invoke the callback
		MyTable["ASpecificKey"] = 123

		-- disconnect the callback
		disconnect()

		-- this won't invoke the callback because we disconnected it
		MyTable["ASpecificKey"] = 567


	3. Connect/disconnect callback for any change in the ProxyTable

		-- this connects the callback to any change
		-- and will immediately invoke the callback on all key/value pairs in the table
		local disconnect = MyTable:changed(function(key, newValue)
			print(key, newValue)
		end

		-- these all invoke the callback
		MyTable.RandomProperty = math.random()
		MyTable.Foo = "Bar"
		MyTable[1] = 2

		-- disconnect it the same as in #2
		disconnect()
]]

-- callbacks can connect to any change in the table
-- and are stored in self.__callbacks with this key
-- (this key can't be equal to an actual property in
-- the ProxyTable or else there will be a collision)
local ALL_CHANGES_KEY = "__ALL_CHANGES__"

local mt = {}
function mt.__index(self, k)
	return self.__data[k]
end

--[[
	Callbacks are invoked when the ProxyTable is mutated
]]
function mt.__newindex(self, k, v)
	-- truly modify the data
	self.__data[k] = v

	-- invoke callbacks specific to this key
	if self.__callbacks[k] then
		for callback, _ in self.__callbacks[k] do
			callback(k, v)
		end
	end

	-- invoke callbacks connected to all changes
	if self.__callbacks[ALL_CHANGES_KEY] then
		for callback, _ in self.__callbacks[ALL_CHANGES_KEY] do
			callback(k, v)
		end
	end
end

--[[
	You can iterate over a ProxyTable like this:

		for k, v in ProxyTable do ... end
]]
function mt.__iter(self)
	return next, self.__data
end

--[[
	#ProxyTable will count all key/value pairs in the table
]]
function mt.__len(self)
	local count = 0
	for k, v in self.__data do
		count += 1
	end
	return count
end

--[[
	To invoke a function when a key/value pair is changed in the table:
		ProxyTable:changed(string key, function callback)

	To invoke a function when any key/value pair is changed in the table:
		ProxyTable:changed(function callback)

	Callbacks are always passed two arguments:
		--> the key that was changed
		--> the new value at that key

	This method returns a function, `disconnect()`, which disconnects the callback

	** If value at key is not nil, the callback will be invoked immediately in this method!
]]
local function changed(self, key, callback)
	-- must pass a callback
	if callback == nil then
		callback = key
		key = ALL_CHANGES_KEY
	end
	assert(typeof(callback) == "function")

	-- get/initialize table of callbacks
	if self.__callbacks[key] == nil then
		self.__callbacks[key] = {}
	end

	-- add callback to that table
	self.__callbacks[key][callback] = true

	-- call callback on current value if non-nil
	if key == ALL_CHANGES_KEY then
		for otherKey, value in self.__data do
			callback(otherKey, value)
		end
	elseif self.__data[key] ~= nil then
		callback(key, self.__data[key])
	end

	-- return disconnect() method
	return function()
		self.__callbacks[key][callback] = nil
		if next(self.__callbacks[key]) == nil then
			self.__callbacks[key] = nil
		end
	end
end

--[[
	newProxyTable(table? data) --> ProxyTable
]]
return function(data)
	return setmetatable({
		-- public
		changed = changed, -- method for connecting to changes

		-- private
		__callbacks = {}, 	-- any key --> { function callback }
							-- <ALL_CHANGES_KEY> --> { function allChangesCallback }

		__data = data or {}, -- the actual data in the table
	}, mt)
end