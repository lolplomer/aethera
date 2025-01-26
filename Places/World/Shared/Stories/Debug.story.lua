local ReplicatedStorage = game:GetService("ReplicatedStorage")
local roact = require(ReplicatedStorage.Utilities.Roact)
local story = require(ReplicatedStorage.PlaceShared.RoactStory)

local create = roact.createElement

local elements = ReplicatedStorage.Utilities.GUI.Theme.Default.Elements

local Label = function(props)
    return create("TextLabel", {
        BackgroundTransparency = 1,
        TextScaled = true,
        TextColor3 = Color3.new(1,1,1) ,
        Text = props.Text;
        Size = UDim2.fromScale(1,0.035);
        Position = UDim2.fromScale(0,0);
        AnchorPoint = Vector2.new();
        TextXAlignment = 'Right';
    });
end


local component = function()

    
    
    return create("Frame", {
        Size = UDim2.fromScale(0.4,.7);
        Position = UDim2.fromScale(.98,0.5);
        AnchorPoint = Vector2.new(1,0.5);
        Transparency = 1;

    }, {
        create("UIListLayout"),
        create(Label, {Text = "Mob Pathfinding Calls: 323/s"});
        create(Label, {Text = "Mob Pathfinding Calls: 323/s"});
        create(Label, {Text = "Mob Pathfinding Calls: 323/s"});
        create(Label, {Text = "Mob Pathfinding Calls: 323/s"});

    });

end

return story(component)