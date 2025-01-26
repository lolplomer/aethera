local ReplicatedStorage = game:GetService("ReplicatedStorage")
local roact = require(ReplicatedStorage.Utilities.Roact)
local story = require(ReplicatedStorage.PlaceShared.RoactStory)

local create = roact.createElement

local Knit = require(ReplicatedStorage.Packages.Knit)
local SystemMonitor = Knit.GetController("SystemMonitor")

type Signal = {
    Connect: (self: Signal, connection : (any) -> nil) -> nil;
}

type Tracker = {
    Label: (number) -> string;
    Changed: Signal;
}

type Props = {
    Trackers: {Tracker}
}

local label = function(props: {Tracker: Tracker})

    local value, setValue = roact.useBinding(0);

    roact.useEffect(function()
        local connection = props.Tracker.Changed:Connect(setValue)

        return function ()
            connection:Disconnect()
        end
    end)

    return create("TextLabel", {
        BackgroundTransparency = 1,
        TextScaled = true,
        TextColor3 = Color3.new(1,1,1) ,
        Text = value:map(props.Tracker.Label) ;
        Size = UDim2.fromScale(1,0.035);
        Position = UDim2.fromScale(0,0);
        AnchorPoint = Vector2.new();
        TextXAlignment = 'Right';
        LayoutOrder = props.LayoutOrder;
    })
end


local component = function()

    local fragments = {};

    local trackers = SystemMonitor.Trackers

    for i, v in trackers do
        table.insert(fragments, create(label, {Tracker = v, LayoutOrder = i}));
    end;
    
    return create("Frame", {
        Size = UDim2.fromScale(0.4,.5);
        Position = UDim2.fromScale(.98,0.5);
        AnchorPoint = Vector2.new(1,0.5);
        Transparency = 1;
        
    }, {
        create("UIListLayout"),
        create(roact.Fragment, nil, fragments)

    });

end

return {Component = component}