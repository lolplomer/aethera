local ReplicatedStorage = game:GetService("ReplicatedStorage")
local roactStory = require(ReplicatedStorage.PlaceShared.RoactStory)
local roact = require(ReplicatedStorage.Utilities.Roact)

local elements = ReplicatedStorage.Utilities.GUI.Theme.Default.Elements
local TextLabel = require(elements.TextLabel)

local function Customization()
    return roact.createElement('CanvasGroup', {
        Size = UDim2.fromScale(1,1),
        BackgroundTransparency = 1,
    }, {
        roact.createElement('UIPadding', {
            PaddingLeft = UDim.new(0,10),
            PaddingTop = UDim.new(0,10),
            PaddingRight = UDim.new(0,10),
            PaddingBottom = UDim.new(0,10),
        }),

        roact.createElement(TextLabel, {
            TextButton = true,

            Size = UDim2.fromScale(.1,.05),

            Text = `< Back`,

            [roact.Event.Activated] = function()
                print('clicked')
            end
        })
        
    })    
end

return roactStory(Customization)