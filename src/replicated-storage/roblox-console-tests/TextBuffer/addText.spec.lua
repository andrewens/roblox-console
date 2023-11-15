return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local TextBuffer = require(ReplicatedStorage:FindFirstChild("TextBuffer"))
	local ADD_TEXT_TEST_CASES = require(script.Parent:FindFirstChild("ADD_TEXT_TEST_CASES"))

	-- read file
	local MAX_CHARS_PER_LINE = ADD_TEXT_TEST_CASES[1]

	-- create buffer
	local Buffer = TextBuffer()
	Buffer.charsPerLine(MAX_CHARS_PER_LINE)

    -- test adding text to TextBuffer and check that it wraps text correctly
	for i = 2, #ADD_TEXT_TEST_CASES, 2 do
		-- read file
		local textToAdd = ADD_TEXT_TEST_CASES[i]
		local expectedResult = ADD_TEXT_TEST_CASES[i + 1]
		local testNumber = i / 2
		testNumber = (if testNumber < 10 then "0" else "") .. tostring(testNumber)

        -- add text & compare with expected result
		it("Test #" .. testNumber, function()
            Buffer.addText(textToAdd)
			if not Buffer.isEqual(expectedResult) then
                error("Failed Test #" .. testNumber)
			end
		end)
	end
end
