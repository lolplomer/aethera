local ReplicatedStorage = game:GetService("ReplicatedStorage")
local roactStory = require(ReplicatedStorage.PlaceShared.RoactStory)
local roact = require(ReplicatedStorage.Utilities.Roact)

return roactStory(function()
    return roact.createElement('Frame',{
        Size = UDim2.fromScale(.5,.5),
        AnchorPoint = Vector2.new(.5,.5),
        Position = UDim2.fromScale(.5,.5),
        BackgroundColor3 = Color3.new(1,1,1)
    })    
end)