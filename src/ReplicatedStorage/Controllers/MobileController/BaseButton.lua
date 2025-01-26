local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BaseButton = {}
BaseButton.__index = BaseButton

local Packages = ReplicatedStorage.Packages

local Signal = require(Packages.Signal)
local Trove = require(Packages.Trove)
local Knit = require(ReplicatedStorage.Packages.Knit)
local InputController

function BaseButton.new(Data)
    if not InputController then
        InputController = Knit.GetController('InputController')
    end

    local self = setmetatable({
        Name = Data.Name,
        Keybind = Data.Keybind,
        Analog = Data.Analog,
        Position = Data.Position,
        Scale = Data.Scale,
        PressBegan = Signal.new(),
        PressEnded = Signal.new(),
        AnalogMoved = Signal.new(),
        AnalogDirection = Vector2.new(),
    }, BaseButton)

    if self:HasAnalog() then
        self.AnalogMoved:Connect(function(direction: Vector2)
            self.AnalogDirection = direction.Unit
        end)    
    end

    if self.Keybind ~= nil then
        self.PressBegan:Connect(function()
            InputController:TriggerKeybind(self.Keybind, 1)
        end)

        self.PressEnded:Connect(function()
            InputController:EndKeybindTrigger(self.Keybind, 1)
        end)
    end
    

    return self
end

function BaseButton:HasAnalog()
    return self.Analog == true;
end


return BaseButton
