local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local BridgeNet2 = require(ReplicatedStorage.Packages.bridgenet2)

local StatFormula = require(ReplicatedStorage.Utilities.Misc.StatFormula)

local PlayerDataService, KeybindService, InventoryService, StatService

local CombatService = Knit.CreateService {
    Name = "CombatService",
    Client = {},
}
CombatService.HitboxVisualization = true

local CombatData = {}

local GameModules = ReplicatedStorage.GameModules
local CombatFolder = GameModules.Combat
local States = require(CombatFolder.States)

local StateChanged = BridgeNet2.ReferenceBridge('StateChanged')
local Util = require(ReplicatedStorage.Utilities.Util)

local packet = require(ReplicatedStorage.Packets.Combat)

local Default = {
    NormalAttackHitbox = 7
}

local minimumDistance = 9


local function DefaultDamageEffect(humanoid: Humanoid, damage: number)
    humanoid:TakeDamage(damage)
end

local function new(name, props)
    local instance = Instance.new(name)
    for prop, value in props do
        instance[prop] = value
    end
    return instance
end

local function VisualizeHitbox(CF, Size)
    if CombatService.HitboxVisualization then
        Debris:AddItem(new('Part', {
            CFrame = CF,
            Size = Size,
            Anchored = true,
            CanCollide = false,
            Transparency = 0.7,
            CanQuery = false,
            CanTouch = false,
            Parent = workspace.Terrain
        }), 0.4)
    end
end

function CombatService:KnitStart()
    
end

function CombatService:KnitInit()
    PlayerDataService = Knit.GetService("PlayerDataService")
    KeybindService = Knit.GetService("KeybindService")
    InventoryService = Knit.GetService("InventoryService")
    StatService = Knit.GetService('StatService')

    KeybindService
    -- :SetDefaultKeybind("Block", Enum.KeyCode.F)
    -- :SetDefaultKeybind("M1", Enum.UserInputType.MouseButton1)
    :SetDefaultKeybind("WeaponEquipmentSwitchPrevious", Enum.KeyCode.Q)
    :SetDefaultKeybind("WeaponEquipmentSwitchNext", Enum.KeyCode.E)

    for Name, Info in States do
        for index, key in Info.Keys do
            KeybindService:SetDefaultKeybind(Name, key, index)
        end
    end
 
    PlayerDataService.PlayerAdded:Connect(function(player: Player)
        CombatData[player] = {
            State = nil,
            StateIndex = nil,
        }
        
        local PlayerStats = StatService:GetStats(player)

        Util.CharacterAdded(player, function(character: Model)
            CollectionService:AddTag(character:WaitForChild('HumanoidRootPart'), 'Entity')
            
            local humanoid: Humanoid = character:WaitForChild('Humanoid')

            local function SetHP(HP)
                print('Changed HP')
                local scale = humanoid.Health/humanoid.MaxHealth
                humanoid.MaxHealth = HP
                humanoid.Health = HP * scale
            end
 
            SetHP(PlayerStats:Get('HP'))
            PlayerStats.Changed.HP:Connect(SetHP)
        end)

        player.Chatted:Connect(function(msg)
            local args = msg:split(' ')
            if args[1] == 'sethp' then
                player.Character.Humanoid.Health = tonumber(args[2])
            end
        end)
    end)

    game.Players.PlayerRemoving:Connect(function(player)
        CombatData[player] = nil
    end) 

    StateChanged:Connect(function(player, content)
        local State, index = table.unpack(content)
        local Data = CombatData[player]

        Data.State = State
        Data.StateIndex = index
    end)

    KeybindService:OnKeybindTrigger('WeaponEquipmentSwitchPrevious', function(player: Player)
        local Inventory = InventoryService:GetInventory(player)
        Inventory:PreviousEquipment('Weapon')
       -- print('prev')
    end)

    KeybindService:OnKeybindTrigger('WeaponEquipmentSwitchNext', function(player: Player)
        local Inventory = InventoryService:GetInventory(player)
        Inventory:NextEquipment('Weapon')
       -- print('next')
    end)

    packet.NormalAttack.listen(function(target: Model, attacker: Player)
        local root = target.HumanoidRootPart

        print('packet received',target,attacker)
        
        local char = attacker.Character
        local player = game.Players:GetPlayerFromCharacter(target)
        local attackerStats = StatService:GetStats(attacker)

        local targetStats

        if player then
            if (char.HumanoidRootPart.Position - root.Position).Magnitude < minimumDistance then
                targetStats = StatService:GetStats(player)
            end    
        else
            local MobService = Knit.GetService('MobService')
            local mob = MobService:GetMobData(target)
            if mob and mob:Distance(char.HumanoidRootPart.Position) < minimumDistance then
                targetStats = mob.Stats
            end
        end

        print(targetStats)

        if targetStats and attackerStats then
            local damage = CombatService:CalculateDamage(targetStats, attackerStats)
            target.Humanoid:TakeDamage(damage)
        end
    end)
end

function CombatService:CalculateDamage(targetStats, attackerStats)
    local AttackerATK = attackerStats.Data.FullStats.ATK
    local TargetDEF = targetStats.Data.FullStats.DEF

    return StatFormula.GetBaseDamage(AttackerATK, TargetDEF)
end

function CombatService:DamageWithinBox(data : {CFrame: CFrame, Size: Vector3, OverlapParams: OverlapParams?, StatModifier: {}, DamageModifier: () -> nil?, Effect: () -> nil?})
    data.Effect = data.Effect or DefaultDamageEffect

    local overlap = OverlapParams.new()
    overlap.FilterType = Enum.RaycastFilterType.Include
    overlap.FilterDescendantsInstances = CollectionService:GetTagged('Entity')
    if data.OverlapParams then
        for property, value in data.OverlapParams do
            overlap[property] = value
        end
    end

    local StatService = Knit.GetService('StatService')
    local MobService = Knit.GetService('MobService')

    VisualizeHitbox(data.CFrame, data.Size)

    for _, rootPart in workspace:GetPartBoundsInBox(data.CFrame, data.Size, overlap) do
        local character = rootPart.Parent
        local player = game.Players:GetPlayerFromCharacter(character)
        local mobData = MobService:GetMobData(character)

        local targetStats
        if player then
            targetStats = StatService:GetStats(player)
        elseif mobData then
            targetStats = mobData.Stats
        end

        if targetStats then
            local AttackerATK = data.StatModifier.Data.FullStats.ATK
            local TargetDEF = targetStats.Data.FullStats.DEF

            local damage = StatFormula.GetBaseDamage(AttackerATK, TargetDEF)
            if data.DamageModifier then
                damage = data.DamageModifier(damage, data.StatModifier, targetStats)
            end

            data.Effect(character.Humanoid, damage)
        end
    end
end

function CombatService.Client:NormalAttack(player: Player, data)
    data = data or {}
    local StatService = Knit.GetService('StatService')

    local PlayerStats = StatService:GetStats(player)
    local character = player.Character

    if character then
        local root = character.HumanoidRootPart
        data.CFrame = data.CFrame or root.CFrame * CFrame.new(0,0,-Default.NormalAttackHitbox/2)
        data.Size = data.Size or Vector3.new(Default.NormalAttackHitbox,Default.NormalAttackHitbox,Default.NormalAttackHitbox)

        CombatService:DamageWithinBox {
            CFrame = data.CFrame,
            Size = data.Size,
            StatModifier = PlayerStats,
            Effect = function(humanoid, damage)
                if humanoid.Parent ~= character then
                    print(damage)
                    humanoid:TakeDamage(damage)
                end
            end
        }
    end
    
    
end

function CombatService.Client:SetState(Player, State, StateIndex)
    local PlayerStateService = Knit.GetService("PlayerStateService")
    local PlayerState = PlayerStateService:GetPlayerState(Player)

    PlayerState:SetMultiple ({
        CombatState = State,
        CombatStateIndex = StateIndex
    })
end


return CombatService
