local ReplicatedStorage = game:GetService("ReplicatedStorage")
local packages = ReplicatedStorage:WaitForChild"Packages"

local react = require(packages:WaitForChild"react")

local component = react.Component:extend('test')

function component:init()
    self.ref1 = react.createRef()
end

function component:componentDidMount()
    local frame = self.ref1.current
   -- print(frame,'ref')
end

function component:render()
    return react.createElement('Frame', {
        AnchorPoint = Vector2.new(1,0),
        Size = UDim2.fromScale(0.3,1),
        Position = UDim2.fromScale(1,0),
        Visible = false,
        ref = self.ref1
    })
end


return component 