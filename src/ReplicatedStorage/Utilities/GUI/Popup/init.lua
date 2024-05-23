local ReplicatedStorage = game:GetService("ReplicatedStorage")
local roact = require(ReplicatedStorage:WaitForChild('Utilities'):WaitForChild('Roact'))
local Popup = {}

Popup.Layouts = {}

function Popup.CreateLayout(element, props)
    print('Creating layout:',props)
    local Layout = Popup.Layouts[props.LayoutType or 'Normal']

    return roact.createElement('ScreenGui', {
        DisplayOrder = 100,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
    }, {
        Frame = roact.createElement(Layout, props, {
            Content = element
        })
    })
end

for _, v in script:GetChildren() do
    Popup.Layouts[v.Name] = require(v)
end

return Popup