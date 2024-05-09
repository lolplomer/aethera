local ReplicatedStorage = game:GetService("ReplicatedStorage")
local roact = require(game.ReplicatedStorage:WaitForChild('Utilities'):WaitForChild('Roact'))
local Knit = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Knit'))

local GUI = Knit.GetController('GUI')

return function (props)
    local buttons = {}

    local padding = props.Padding or 10

    for i, btn in props.Buttons do
        -- local element = GUI.newElement("TextButton", {
        --     Text = btn.Text,
        --     Size = UDim2.fromScale(1,1/#props.Buttons-0.02),
        --     LayoutOrder = i,
        --     Callback = btn.Callback
        -- })
        local element = roact.createElement('TextButton', {
            Text = btn.Text,
            Size = UDim2.fromScale(1,1/#props.Buttons-0.02),
            BackgroundColor3 = Color3.new(1,1,1),
            BackgroundTransparency = 1,
            LayoutOrder = i,
            [roact.Event.Activated] = btn.Callback,
            [roact.Event.MouseEnter] = function(rbx)
                GUI.Tween(rbx, {BackgroundTransparency = 0.8})
                --rbx.BackgroundTransparency = 0.6
            end,
            [roact.Event.MouseLeave] = function(rbx)
                task.wait()
                GUI.Tween(rbx, {BackgroundTransparency = 1})
            end,
            Font = Enum.Font.Fondamento,
            TextColor3 = Color3.new(1,1,1),
            TextScaled = true,
            BorderSizePixel = 0,
            AutoButtonColor = false,
        }, {
            Corner = roact.createElement("UICorner")
        })
        table.insert(buttons, element)
    end

    return roact.createElement('Frame', {
        BackgroundTransparency = 1,
        Size = UDim2.new(1,-padding,1,-padding),
        Position = UDim2.fromScale(0.5,0.5),
        AnchorPoint = Vector2.new(0.5,0.5)
    }, {
        ListLayout = roact.createElement("UIListLayout", {
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0.02,0)
        }),
        Buttons = roact.createFragment(buttons)
    })
end