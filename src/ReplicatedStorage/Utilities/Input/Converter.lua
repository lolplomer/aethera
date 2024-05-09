local KeyCodes = require(script.Parent:WaitForChild"KeyCodes")
local UserInputTypes = require(script.Parent:WaitForChild"UserInputTypes")

local InputConverter = table.freeze({
    {
        Condition = function(input: EnumItem)
            return input.EnumType == Enum.KeyCode
        end,
        ToData = function(input: EnumItem)
            return input.Value
        end,
        ToInput = function(data)
            return Enum.KeyCode[KeyCodes[data]]
        end
    },
    {
        Condition = function(input: EnumItem)
            return input.EnumType == Enum.UserInputType
        end,
        ToData = function(input: EnumItem)
            return input.Value
        end,
        ToInput = function(data)
            return Enum.UserInputType[UserInputTypes[data]]
        end
    }
})

local API = {}

function API:ConvertInput(input)
    for index, converter in InputConverter do
        if converter.Condition(input) then
            return {index, converter.ToData(input)}
        end
    end
end

function API:ReadInputData(inputData)
    return InputConverter[inputData[1]].ToInput(inputData[2])
end

function API:ConvertInputObject(inputObject: InputObject)
   return inputObject.UserInputType == Enum.UserInputType.Keyboard and inputObject.KeyCode or inputObject.UserInputType
end

function API:GetConverter()
    return InputConverter
end

return API