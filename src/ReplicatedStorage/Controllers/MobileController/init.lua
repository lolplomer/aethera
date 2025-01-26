type MobileButton = {
    Name: string,
    Keybind: string,
    Analog: boolean,
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local MobileController = Knit.CreateController { Name = "MobileController" }

local MobileButtons = {}

local Started = false

local BaseButton = require(script.BaseButton)

local GUI

function MobileController:UpdateUI()
    task.spawn(function()
        while not GUI.Started do
            task.wait()
            
        end
        print'Updating Mobile UI Controller'
        GUI:UpdateUI("MobileUI", MobileButtons)
    end)
end

function MobileController:NewButton(Data)
    self:RemoveButton(Data.Name)

    local Button = BaseButton.new(Data)

    MobileButtons[Data.Name] = {
        Button = Button,
        Position = Button.Position,
        AnchorPoint = Button.AnchorPoint,
        Scale = Button.Scale or 0.1,
    }

    if Started == true then
        self:UpdateUI()
    end

    return function ()
        self:RemoveButton(Data.Name)
    end
end

function MobileController:RemoveButton(Name)
    if MobileButtons[Name] then
        MobileButtons[Name] = nil
        self:UpdateUI()
    end
end

function MobileController:KnitStart()
    GUI = Knit.GetController("GUI")
    Started = true
    self:UpdateUI()
end

return MobileController