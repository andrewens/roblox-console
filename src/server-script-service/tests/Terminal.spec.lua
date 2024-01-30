return function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Console = require(ReplicatedStorage:FindFirstChild("Console"))

    local function shouldHaveType(v1, typeName)
        if typeof(v1) ~= typeName then
            error(tostring(v1) .. " isn't a " .. tostring(typeName) .. "!")
        end
    end
    it("Console.new is a function", function()
        shouldHaveType(Console.new, "function")
    end)
end
