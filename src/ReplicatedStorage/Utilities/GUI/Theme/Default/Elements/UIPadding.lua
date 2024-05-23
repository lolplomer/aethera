local ReplicatedStorage = game:GetService("ReplicatedStorage")
local roact = require(ReplicatedStorage:WaitForChild('Utilities'):WaitForChild('Roact'))

return function (props)
    return roact.createElement('UIPadding', {
        PaddingBottom = props.Padding,
        PaddingLeft = props.Padding,
        PaddingRight = props.Padding,
        PaddingTop = props.Padding
    })
end