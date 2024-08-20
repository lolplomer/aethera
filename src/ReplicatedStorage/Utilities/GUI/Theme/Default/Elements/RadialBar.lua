local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local RadialImage = require(ReplicatedStorage.Utilities.GUI.RadialImage)

local FullImage = "rbxassetid://18428019493"

local RadialBarProperties = RadialImage.new([[
{"version":1,"size":147,"count":120,"columns":6,"rows":6,"images":["rbxassetid://18422266837","rbxassetid://18422266601","rbxassetid://18422266291","rbxassetid://18422265966"]}
]])

local roact = require(ReplicatedStorage.Utilities.Roact)

return function (props)

    local ref = roact.useRef()


    roact.useEffect(function()
        local alpha = props.Alpha or 0
        
        
        local function update()

            if props.Time then       
                local t = props.Time
                local now = os.clock()
                if t.End >= 0 then
                    local duration = t.End - t.Start
                    local elapsedTime = now - t.Start
                    alpha = 1 - elapsedTime / duration    
                else
                    alpha = 1
                end
                
            end

            local x,y,page = RadialBarProperties:GetFromAlpha(alpha)
            local bar = ref.current

            bar.Image = alpha <= 0 and "" or RadialBarProperties.config.images[page]
            bar.ImageRectSize = Vector2.new(RadialBarProperties.config.size, RadialBarProperties.config.size)
            bar.ImageRectOffset = Vector2.new(x, y)
        end

        update()

        if props.Time then
            local conn = RunService.RenderStepped:Connect(update)
    
            return function ()
                conn:Disconnect()
            end
        end

    end)

    return roact.createElement('ImageLabel', {
        Image = 'rbxassetid://18428019493',
        BackgroundTransparency = 1,

        Position = props.Position,
        Size = props.Size or UDim2.fromScale(0.3,0.3),
        AnchorPoint = props.AnchorPoint,
        ImageColor3 = props.InnerColor or Color3.fromRGB(180,180,180),
        ImageTransparency = 1,
    }, {
        roact.createElement('UIAspectRatioConstraint'),
        roact.createElement('ImageLabel', {
            BackgroundTransparency = 1,
            ref = ref,
            Size = UDim2.fromScale(1,1),
            ImageTransparency = 0.2,
            ImageColor3 = props.Color
        })
    })
    
    
end