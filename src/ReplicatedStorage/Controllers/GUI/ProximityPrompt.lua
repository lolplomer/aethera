local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Util = require(ReplicatedStorage.Utilities.Util)

local ReactRoblox = require(ReplicatedStorage.Packages["react-roblox"])

local GUI = require(script.Parent)
local module = {}

local function AddPrompt(prompt: ProximityPrompt)
    local InputController = Knit.GetController('InputController')

    prompt.Style = Enum.ProximityPromptStyle.Custom
    prompt.Exclusivity = Enum.ProximityPromptExclusivity.OneGlobally
    prompt.RequiresLineOfSight = false
    prompt.KeyboardKeyCode = InputController:GetInputOfKeybind('Interact')

    local _trove = Trove.new()

    local cleanup = _trove:WrapClean()

    prompt.PromptShown:Connect(function(inputType)
        cleanup()

        local container = Util.new('BillboardGui', {
            Parent = game.Players.LocalPlayer.PlayerGui,
            Size = UDim2.fromScale(10,6),
            AlwaysOnTop = true,
            ResetOnSpawn = false,
            ZIndexBehavior = 'Sibling',
            ClipsDescendants = false,
        })
        local root = ReactRoblox.createRoot(container)
    
        local function updateAdornee()
            container.Adornee = prompt.Parent:IsA('Model') and prompt.Parent.PrimaryPart or prompt.Parent
        end        

       
        

        --root:render()

        --_trove:Add(container)
        _trove:Connect(prompt.AncestryChanged, updateAdornee)
        _trove:Add(InputController:OnKeybindTrigger('Interact', function()
            prompt:InputHoldBegin()
        end))
        _trove:Add(InputController:OnKeybindTriggerEnded('Interact', function()
            prompt:InputHoldEnd()
        end))
        _trove:Add(function()
            prompt:InputHoldEnd()
            root:render( GUI.newElement('ProximityPrompt', {ProximityPrompt = prompt, Disabled = true}))
            task.delay(1, function()
                root:unmount()
                container:Destroy()
            end)
        end)
        root:render( GUI.newElement('ProximityPrompt', {ProximityPrompt = prompt, Disabled = false}))
        updateAdornee()
    end)

    prompt.PromptHidden:Connect(cleanup)
end

Knit.OnStart():andThen(function()
    
    for _, prompt in CollectionService:GetTagged('Proximity') do
        AddPrompt(prompt)
    end
    CollectionService:GetInstanceAddedSignal('Proximity'):Connect(AddPrompt)

end)


return module