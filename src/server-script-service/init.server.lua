--[[
    Run unit tests for `roblox-console`.

    Dependencies:
        * TestEZ (ReplicatedStorage)
]]

-- dependency
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestEZ = require(ReplicatedStorage:FindFirstChild("TestEZ"))
local TestsFolder = script.Parent

-- const
local RUN_TESTS = true

-- init
if RUN_TESTS then
	TestEZ.TestBootstrap:run({ TestsFolder })
end
