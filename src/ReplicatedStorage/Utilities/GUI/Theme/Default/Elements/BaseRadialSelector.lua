
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local roact = require(ReplicatedStorage.Utilities.Roact)
local radialImage = require(ReplicatedStorage.Utilities.GUI.RadialImage)
local trove = require(ReplicatedStorage.Packages.Trove)
local knit = require(ReplicatedStorage.Packages.Knit)

local roactSpring = require(ReplicatedStorage.Packages.ReactSpring)

local image = {
    stroke = 'rbxassetid://18391056279',
    inner = 'rbxassetid://18391056561'
}

local config = {
    inner = [[{"version":1,"size":300,"count":60,"columns":3,"rows":3,"images":["rbxassetid://18391329288","rbxassetid://18391329034","rbxassetid://18391328793","rbxassetid://18391328545","rbxassetid://18391328303","rbxassetid://18391328050","rbxassetid://18391314912"]}]],
    stroke = [[{"version":1,"size":300,"count":60,"columns":3,"rows":3,"images":["rbxassetid://18394060445","rbxassetid://18394059947","rbxassetid://18394059947","rbxassetid://18394058934","rbxassetid://18394058564","rbxassetid://18394058564","rbxassetid://18394057951"]}]]
}

local radial = {
    inner = radialImage.new(config.inner),
    stroke = radialImage.new(config.stroke)
}

local PlayerModule = require(game.Players.LocalPlayer.PlayerScripts.PlayerModule)
local Cameras = PlayerModule:GetCameras()

return function (props)

    local count = #props.Items
    local alpha = 1/count
    local totalAngle = alpha * 360 
    local radius = 0.3

    local refs = {
        inner = roact.useRef(),
        stroke = roact.useRef()
    }
    local canvas = roact.useRef()
    local items = {}

    local spring, api = roactSpring.useSpring(function()
        return {
            transparency = 1,
            hover = .7,
            config = {duration = 0.1}
        }
    end)

    for i, element in props.Items do
        local rad = math.rad(totalAngle * (count - i) - totalAngle/2)
        if roact.isValidElement(element) then
            items[i] = roact.createElement('Frame', {
            
                Position = UDim2.fromScale(
                    0.5 + radius * -math.sin(rad),
                    0.5 + radius * -math.cos(rad)
                ),
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(.15,.15),
                ZIndex = 2,
                AnchorPoint = Vector2.new(0.5,0.5),
            }, {
                element
            })
        end
    end

    roact.useEffect(function()
        local _trove = trove.new()

        local selection = props.Selection or 1

        local function setSelection(index)
            selection = index
            refs.inner.current.Rotation = index * totalAngle
            api.start {from = {hover = 1}, to = {hover = 0.7}, reset = true}
        end

        --local MouseLockController = Cameras.activeMouseLockController
        local MouseLockController = knit.GetController("MouseLockController")
        local MouseLocked = MouseLockController:GetIsMouseLocked()
        local isVisible = false

        local function setVisible(visible)
            
            isVisible = visible

            if visible and not props.Disabled then
                canvas.current.Visible = true
                api.start {transparency = 0}    

               MouseLockController:DisableMouseLock()
                
            else
                api.start ({transparency = 1}):andThen(function()
                    canvas.current.Visible = false
                end)
                MouseLockController:RestoreMouseLock()
            end
        end

        for name, ref in refs do
            local label: ImageLabel = ref.current
            if label then
                local self = radial[name]
                
	            local x, y, page = self:GetFromAlpha(alpha)

                label.ImageRectSize = Vector2.new(self.config.size, self.config.size)
                label.ImageRectOffset = Vector2.new(x, y)
                label.Image = alpha <= 0 and "" or self.config.images[page]
            end 
        end

        _trove:Connect(UserInputService.InputChanged, function(input: InputObject)
            if input.UserInputType ==Enum.UserInputType.MouseMovement and isVisible then
                local position = input.Position
                local resolution = workspace.CurrentCamera.ViewportSize

                local delta = Vector2.new(position.X,position.Y) - resolution/2
                local angle = math.deg(math.atan2(delta.X, delta.Y))

                if angle < 0 then
                    angle = angle + 360
                end

                local radialCenterAngle = (angle + (totalAngle/2)) % 360
                local finalAngle = 180-radialCenterAngle 

                refs.stroke.current.Rotation = finalAngle

                local _selection = math.round((finalAngle%360)/totalAngle)
                if _selection ~= 0 and _selection ~= selection then
                    setSelection(_selection)
                end

            end
        end)

        if props.Keybind then
            local InputController = knit.GetController('InputController')
            local triggerCallback = props.TriggerCallback
            local selectionChanged = props.SelectionChanged
            local pressing = false

            _trove:Add(InputController:OnKeybindTrigger(props.Keybind, function()
                pressing = true 
                --task.wait(0.1)
                if pressing then
                    setVisible(true)
                end   
                
            end))

            _trove:Add(InputController:OnKeybindTriggerEnded(props.Keybind, function()
                pressing = false

                setVisible(false)
                
                if triggerCallback and canvas.current.Visible == false then
                    triggerCallback(selection)
                elseif selectionChanged and canvas.current.Visible == true then
                    selectionChanged(selection)
                end

            end))
                
            _trove:Add(function()
                pressing = false
            end)
        end

        setSelection(selection)

        return _trove:WrapClean()
    end)

    return roact.createElement('CanvasGroup', {
        AnchorPoint = Vector2.new(.5,.5),
        Position = UDim2.fromScale(.5,.5),
        Size = UDim2.fromScale(.65,.65),
        BackgroundTransparency = 1,
        GroupTransparency = spring.transparency,
        Visible = not props.Disabled,
        ref = canvas
    }, {
        roact.createElement('UIAspectRatioConstraint'),
        roact.createElement('ImageLabel', {
            Image = image.inner,
            ImageColor3 = Color3.new(),
            ImageTransparency = 0.8,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1,1),
        }, {
            Selector = roact.createElement('ImageLabel', {
                Image = image.stroke,
                Size = UDim2.fromScale(1,1),
                BackgroundTransparency = 1 ,
                ref = refs.stroke,
                ZIndex = 2
            }),
            Inner = roact.createElement('ImageLabel', {
                Image = image.inner,
                Size = UDim2.fromScale(1,1),
                BackgroundTransparency = 1,
                ref = refs.inner,
                ImageTransparency = spring.hover
            }),
            Center = roact.createElement('Frame', {
                Size = UDim2.fromScale(0.2,0.2),
                BackgroundColor3 = Color3.fromHex('A6AEC1'),
                Position = UDim2.fromScale(0.5,0.5),
                AnchorPoint = Vector2.new(0.5,0.5),
                ZIndex = 2,
            }, {
                UICorner = roact.createElement('UICorner', {
                    CornerRadius = UDim.new(1,0)
                }),
                Stroke = roact.createElement('UIStroke', {
                    Thickness = 8,
                    Color = Color3.new(1,1,1)
                })
            }),
            Items = roact.createElement(roact.Fragment, nil, items),
            
        })
    })

  
end
