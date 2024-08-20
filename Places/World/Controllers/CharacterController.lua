local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local ReactRoblox = require(ReplicatedStorage.Packages["react-roblox"])

local GameModules = ReplicatedStorage:WaitForChild"GameModules"
local CombatFolder = GameModules:WaitForChild("Combat")
local CharacterModule = require(CombatFolder:WaitForChild"Character")

local Util = require(ReplicatedStorage.Utilities.Util)
local Player = game.Players.LocalPlayer
local Trove = require(ReplicatedStorage.Packages.Trove)

local Signal = require(ReplicatedStorage.Packages.Signal)

local CharacterController = Knit.CreateController { Name = "CharacterController" }
CharacterController.StateChanged = Signal.new()
CharacterController.StaminaChanged = Signal.new()

local packet = require(ReplicatedStorage.Packets.Combat)

local Char

local State = {
    State = nil,
    Index = nil
}

function CharacterController:KnitStart()
    
    Util.CharacterAdded(Player, function(Character: Model)
        Char = CharacterModule:Initialize(Character)

        Char.StateChanged:Connect(function(state, index)
            State.State = state
            State.Index = index
            self.StateChanged:Fire(state, index)
        end)
        
        Char.StaminaChanged:Connect(function(stamina, max)
            self.StaminaChanged:Fire(stamina, max)
        end)
    end, false)
end

function CharacterController:AwaitCharacter()
    while not Char do 
        task.wait() 
    end
end

function CharacterController:GetStamina()
    if Char then
        return Char.Stamina, Char.MaxStamina
    else
        return 0,1
    end
end

function CharacterController:CastNormalAttack()
    local origin: CFrame = Char.Root.CFrame
    local size = Vector3.new(7,7,1)
    local params = RaycastParams.new()

    local filter = CollectionService:GetTagged('Entity')
    
    local index = table.find(filter, Char.Root)
    if index then
        table.remove(filter, index)
    end

    params.FilterDescendantsInstances = filter
    params.FilterType = Enum.RaycastFilterType.Include
    
    local result = workspace:Blockcast(origin, size, origin.LookVector * 7, params)

    if result and result.Instance then
        local Model = result.Instance.Parent

        Knit.GetController('EffectClient'):SpawnEffect('Hit', {
            Parent = result.Instance,
            CFrame = CFrame.new(result.Position)
        })
        packet.NormalAttack.send(Model)
        
       -- print('Hit', Model)
    end
end

function CharacterController:ChangeState(state, index)
    if Char then
        index = index or 1
        Char:ChangeState(state, index)
    end

end

function CharacterController:GetState()
    return State.State, State.Index
end

function CharacterController:GetCharacter()
    return Char
end

function CharacterController:PopDamageCounter(data)
    
    local GUI = Knit.GetController('GUI')

    local attachment = Util.new('Attachment', {
        Parent = workspace.Terrain,
        WorldPosition = data.position
    })

    local gui = Util.new('BillboardGui', {
        ZIndexBehavior = 'Sibling',
        Parent = attachment,
        Size = UDim2.new(20,10,data.size or .8,10),
        StudsOffsetWorldSpace = data.offset,
        AlwaysOnTop = true,
        ClipsDescendants = false,
        MaxDistance = 400,
    })

    local component = GUI.newElement('DamageCounter', {
        Damage = data.damage,
        Crit = data.crit
    })

    local root = ReactRoblox.createRoot(gui)

    root:render(component)

    local _trove = Trove.new()
    _trove:Add(function()
        root:unmount()
    end)
    _trove:AttachToInstance(attachment)

    Debris:AddItem(attachment, 2)
end

function CharacterController:KnitInit()


    packet.DamageCounter.listen(function(data)
        data.damage = math.floor(data.damage)
        data.offset = Vector3.new(math.random(-2,2),math.random(-2,2),math.random(-2,2))
        self:PopDamageCounter(data)

        if data.crit then
            self:PopDamageCounter({
                position = data.position,
                offset = data.offset - Vector3.new(0,.6,0),
                crit = true,
                damage = 'CRIT!',
                size = 0.5
            })
        end
    end)
end


return CharacterController
