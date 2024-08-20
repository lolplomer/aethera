local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local roact = require(ReplicatedStorage.Utilities.Roact)
local knit = require(ReplicatedStorage.Packages.Knit)
local trove = require(ReplicatedStorage.Packages.Trove)
local Util = require(ReplicatedStorage.Utilities.Util)
local ReactSpring = require(ReplicatedStorage.Packages.ReactSpring)

local player = game.Players.LocalPlayer

local GUI = knit.GetController('GUI')

local function StaminaHUD(props)
    local styles, api = ReactSpring.useSpring(function()
        return {stamina = 0, transparency = 1}
    end)

    roact.useEffect(function()
        local CharacterController = knit.GetController('CharacterController')
        
        local _trove = trove.new()

        _trove:Connect(CharacterController.StaminaChanged, function(stamina, max)
            api.start {stamina = stamina/max, transparency = stamina/max >= 1 and 1 or 0}
        end)

        local stamina,max = CharacterController:GetStamina()
        if stamina and max then
            api.start {stamina = stamina/max}    
        end
        

        print(getmetatable(_trove),_trove)

        return _trove:WrapClean()
    end)
    
    return roact.createElement('CanvasGroup', {
        AnchorPoint = Vector2.new(0.5,.5),
        Position = UDim2.fromScale(0.5,.5),
        Size = UDim2.fromScale(1,1),
        BackgroundTransparency = 1,
        GroupTransparency = styles.transparency,
        Visible = not props.Disabled
    
    }, {
        Image = roact.createElement('ImageLabel', {
            Size = UDim2.fromScale(1,1),
            ImageColor3 = Color3.fromHex('9E7F2E'),
            Image = "rbxassetid://17897142973",
            BackgroundTransparency = 1,
        }, {
            Bar = GUI.newElement('ImageBar', {
                Size = UDim2.fromScale(1,1),
                Value = styles.stamina,
                ImageColor3 = Color3.fromHex('FFCB45'),
                Image = "rbxassetid://17897142973",
                Rotation = -90,
            }),
            AspectRatio = roact.createElement('UIAspectRatioConstraint', {AspectRatio = 64/234})
        })
    })
    
    
    

end

return {
    Component = StaminaHUD,

    HUD = true,

    Handle = function(name)
        local gui = Util.new('BillboardGui', {
            Parent = player.PlayerGui,
            AlwaysOnTop = true,
            Size = UDim2.fromScale(1,2),
            StudsOffset = Vector3.new(-2,1,0),
            ResetOnSpawn = false,
            Name = name,
            ZIndexBehavior = 'Sibling'
        })

        if player.Character then
            gui.Adornee = player.Character.HumanoidRootPart
        end
        player.CharacterAdded:Connect(function(character)
            gui.Adornee = character:WaitForChild('HumanoidRootPart')
        end)

        return gui
    end
}