--[[
  The Maid class lets you easily watch and clean up objects, events, and other tasks. 
  Maids were originally implemented by Quenty; this is my own custom implementation with shorter syntax.

  It is *almost* a drop-in replacement for Quenty's Maid class, but with some differences:

  1. Maid:GiveTask(...) can be written instead as Maid(...) to make wrapping callback connections less verbose
    --> this is accomplished using metatables

  2. I personally use camelCase for my objects, and this Maid class supports Maid.destroy with a lowercase 'd'
	as well as Maid.doCleaning & Maid.giveTask
    --> All normal Maid methods (GiveTask, Destroy) with PascalCase are still supported though

  3. The functions defining what a valid "task" is and how to handle them are at the top of the function, so you
      can add new kinds of tasks as necessary

  4. Create new Maid objects with Maid() instead of Maid.new, as such:

    local Maid = require(<Path>.Maid)
    local MyMaidObject = Maid()

  Arguably these changes are mostly due to preference. I like simplicity! Do with it what you will.

  Andrew Ens
  October 2023


  View this gist and more on my github:
	https://gist.github.com/andrewens/
]]

-- private
local function handleTask(task)
    local taskType = typeof(task)
	if taskType == "function" then
		task()
    elseif taskType == "Instance" then
        task:Destroy()
    elseif taskType == "RBXScriptConnection" then
        task:Disconnect()
    else -- tables & what have you
		(task.Destroy or task.destroy or task.Disconnect)(task)
	end
end
local function isValidTask(val)
	local valType = typeof(val)
	return valType == "function"
		or valType == "table" and (val.Destroy or val.destroy)
		or valType == "Instance"
		or valType == "RBXScriptConnection"
end
local function assertIsValidTask(val)
	if not isValidTask(val) then
		error(tostring(val) .. " (type=" .. typeof(val) .. ") is not a valid task for a Maid")
	end
end

-- public
local function giveTask(self, newTask)
	assertIsValidTask(newTask)
	table.insert(self.__tasks, newTask)
end
local function destroy(self)
	for _, task in pairs(self.__tasks) do
		handleTask(task)
	end
	self.__tasks = {}
end

local methodAliases = {
	GiveTask = giveTask,
	giveTask = giveTask,
	Destroy = destroy,
	destroy = destroy,
	doCleaning = destroy,
	DoCleaning = destroy,
}
local mt = {
	__call = giveTask,
	__index = methodAliases,
}

--[[
    newMaid() --> Maid
]]
return function()
	return setmetatable({
		__tasks = {},
	}, mt)
end