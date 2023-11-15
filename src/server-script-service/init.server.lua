-- run unit tests
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestEZ = require(ReplicatedStorage:FindFirstChild("TestEZ"))
local Tests = ReplicatedStorage:FindFirstChild("roblox-console-tests")
TestEZ.TestBootstrap:run({ Tests })
