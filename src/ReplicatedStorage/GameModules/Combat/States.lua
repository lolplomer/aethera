local ReplicatedStorage = game:GetService("ReplicatedStorage")
local States = {}

local Promise = require(ReplicatedStorage:WaitForChild("Utilities"):WaitForChild("Promise"))
local Priority = require(ReplicatedStorage.Utilities:WaitForChild"Priority")
local Trove = require(ReplicatedStorage.Packages.Trove)

States.Attack = {
    Keys = {
        Enum.UserInputType.MouseButton1
    },
    Type = 'SinglePress',
    DelayAfter = 0.3,
}

States.Sprint = {
    Keys = {
        Enum.KeyCode.LeftShift,
        Enum.KeyCode.RightShift
    },
    Type = 'Hold',
    Init = function(Character)
        
    end,
    Trigger = function(Character)

        local Value = Priority.Set(Character.Humanoid, 'WalkSpeed', 28, 2)

        return Promise.new(function()
            
        end):finally(function()
          --  print('Done running')
           Value:Dispose()
        end)
    end
}

return States