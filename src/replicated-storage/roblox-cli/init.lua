local DEFAULT_TEXT_SIZE = 12

local function commandLineInterface(Programs, GuiFrame, textSize)
    --[[
        @param: table Programs
            - { [int i] --> ModuleScript }
            - { [int i] --> Folder }
            - { string programName --> function(CLI, ...): nil }
        @param: Frame? GuiFrame
        @param: int? textSize
        @return: table CLI
    ]]

    -- extract programs
    local ALL_PROGRAMS = {} -- string programName --> function(CLI, ...): nil

    -- define command line interface
    local buffer = {}
    local function input(questionStr)
        local userInput = ""

        return userInput
    end
    local function output(str)
        table.insert(buffer, str)
    end
    local function clear()
        buffer = {}
    end
    local function command(inputStr)

    end
    local function destroy()
        clear()
    end
    local self = {
        buffer = buffer,

        input = input,
        output = output,
        clear = clear,
        command = command,
        destroy = destroy,
    }

    -- build gui
    if GuiFrame then
        textSize = textSize or DEFAULT_TEXT_SIZE
    end

    return self
end

return commandLineInterface
