local ReplicatedStorage = game:GetService("ReplicatedStorage")
local roact = require(ReplicatedStorage:WaitForChild('Utilities'):WaitForChild('Roact'))
local Popup = {}

Popup.Layouts = {}

function Popup.CreateLayout(element, props)
    local Layout = Popup.Layouts[props.LayoutType or 'Normal']

    return roact.createElement(Layout, props, {
        Content = element,
        -- Padding = roact.createElement('UIPadding', {
        --     PaddingBottom = UDim.new(0.05,0),
        --     PaddingTop = UDim.new(0.05,0),
        --     PaddingLeft = UDim.new(0.03,0),
        --     PaddingRight = UDim.new(0.03,0),
        -- })
    })
end

for _, v in script:GetChildren() do
    Popup.Layouts[v.Name] = require(v)
end

return Popup