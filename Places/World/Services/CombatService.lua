local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local BridgeNet2 = require(ReplicatedStorage.Packages.bridgenet2)

local StatFormula = require(ReplicatedStorage.Utilities.Misc.StatFormula)
local Tagger = require(ReplicatedStorage.Utilities.Tagger)

local PlayerDataService, KeybindService, InventoryService, StatService

local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)

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

local minimumDistance = 16

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

local PlayerCombat = {}
PlayerCombat.__index = PlayerCombat

function PlayerCombat.new(player)

    local self =  setmetatable({
        State = nil,
        StateIndex = nil,
        Tagger = Tagger.forInstance(),
        Trove = Trove.new(),
        Player = player,
    }, PlayerCombat)

    self.DamageTaken = self.Trove:Construct(Signal)
    self.DamageDealt = self.Trove:Construct(Signal)
    

    self.Tagger:SetCombatData(self)

    return self
end

function PlayerCombat:Destroy()
    self.Trove:Destroy()
end

function CombatService:KnitInit()
    workspace.Gravity = 110

    game.Players.CharacterAutoLoads = false
    
    PlayerDataService = Knit.GetService("PlayerDataService")
    KeybindService = Knit.GetService("KeybindService")
    InventoryService = Knit.GetService("InventoryService")
    StatService = Knit.GetService('StatService')

    KeybindService
    -- :SetDefaultKeybind("Block", Enum.KeyCode.F)
    -- :SetDefaultKeybind("M1", Enum.UserInputType.MouseButton1)
    :SetDefaultKeybind("WeaponChange", Enum.KeyCode.One)
    :SetDefaultKeybind("ConsumableChange", Enum.KeyCode.Two)

    for Name, Info in States do
        for index, key in Info.Keys do
            KeybindService:SetDefaultKeybind(Name, key, index)
        end
    end
 
    PlayerDataService.PlayerAdded:Connect(function(player: Player)
        CombatData[player] = PlayerCombat.new(player)
        local combat = CombatData[player]
        
        local PlayerStats = StatService:GetStats(player)

        player.Chatted:Connect(function(msg)
            local args = msg:split(' ')
            if args[1] == 'sethp' then
                player.Character.Humanoid.Health = tonumber(args[2])
            end
        end)
        
        Util.CharacterAdded(player, function(character: Model)
            combat.Tagger:Reset()

            CollectionService:AddTag(character:WaitForChild('HumanoidRootPart'), 'Entity')
            CollectionService:AddTag(character.HumanoidRootPart, 'Player')
            CollectionService:AddTag(character, 'Character')

            local humanoid: Humanoid = character:WaitForChild('Humanoid')

            humanoid.Died:Connect(function()
                Knit.GetService('EffectService'):SpawnEffect('Death', {Parent = character.HumanoidRootPart})
                print(player, `was killed by`, combat.Tagger:GetLastTag())
            end)

            local function SetHP(HP)
                --print('Changed HP')
                local scale = humanoid.Health/humanoid.MaxHealth
                humanoid.MaxHealth = HP
                humanoid.Health = HP * scale
            end
 
            SetHP(PlayerStats:Get('HP'))
            PlayerStats.Changed.HP:Connect(SetHP)

            character:WaitForChild('Health'):Destroy()
            --print('Combat Character initiated')
        end,false)

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

    packet.NormalAttack.listen(function(target: Model, attacker: Player)
        self:DealDamage(target, attacker.Character)
    end)

    --[[
    packet.NormalAttack.listen(function(target: Model, attacker: Player)
        local root = target.HumanoidRootPart

      --  print('packet received',target,attacker)
        
        local char = attacker.Character
        local player = game.Players:GetPlayerFromCharacter(target)
        local attackerStats = StatService:GetStats(attacker)

        local targetStats, tagger

        local position
        if player then
            position = root.Position
            if (char.HumanoidRootPart.Position - position).Magnitude < minimumDistance then
                targetStats = StatService:GetStats(player)
                tagger = CombatService:GetTagger(player)
            end    
        else
            local MobService = Knit.GetService('MobService')
            local mob = MobService:GetMobData(target)
            position = mob.Position
            if mob and mob:Distance(char.HumanoidRootPart.Position) < minimumDistance then
                targetStats = mob.Stats
                tagger = mob.Tagger
            end
        end

       -- print(targetStats)

        if targetStats and attackerStats then
            local damage, crit = CombatService:CalculateFinalDamage(targetStats, attackerStats)
            
            if tagger then
                tagger:Tag(attacker, damage)
            end

            target.Humanoid:TakeDamage(damage)

            self:SpawnHitDamage(damage, position, crit)
        end
    end)
    ]]
end

function CombatService:DealDamage(TargetChar, AttackerChar, ModifierDamage)

    local AttackerInfo = self:GetRequiredDamageInfo(AttackerChar)
    local TargetInfo = CombatService:GetRequiredDamageInfo(TargetChar)

    local damage, crit = CombatService:CalculateFinalDamage(TargetInfo.Stats, AttackerInfo.Stats, ModifierDamage)

    if TargetInfo.Mob then
        TargetInfo.Mob:TakeDamage(damage)
    else
        TargetChar.Humanoid:TakeDamage(damage)
    end
    

    self:SpawnHitDamage(damage, TargetInfo.Position, crit)

    TargetInfo.Tagger:Tag(AttackerChar, damage)

    if AttackerInfo.Tagger.CombatData then
        AttackerInfo.Tagger.CombatData.DamageDealt:Fire(TargetChar, damage)
    end
end

function CombatService:GetRequiredDamageInfo(target)
    --local root = target.HumanoidRootPart
    local player = game.Players:GetPlayerFromCharacter(target)

    local targetStats, tagger, position

    local Info
    
    if player then
        position = target.HumanoidRootPart.Position
        targetStats = StatService:GetStats(player)
        tagger = CombatService:GetTagger(player)
        Info = {
            Stats = targetStats,
            Tagger = tagger,
            Position = position
        };
    else
        local MobService = Knit.GetService('MobService')
        local mob = MobService:GetMobData(target)

        position = mob.Root.Position
        targetStats = mob.Stats
        tagger = mob.Tagger

        Info = {
            Stats = targetStats,
            Tagger = tagger,
            Position = position,
            Mob = mob,
        }
    end

    return Info
end

function CombatService:SpawnHitDamage(Damage, Position, Crit)
    packet.DamageCounter.sendToAll({
        damage = Damage,
        position = Position,
        crit = Crit
    })
end

function CombatService:CalculateFinalDamage(targetStats, attackerStats, damageModifier)
    local normal_damage = CombatService:CalculateDamage(targetStats, attackerStats)
    normal_damage = StatFormula.RandomizeDamage(normal_damage, 0.1)

    if damageModifier then
        normal_damage = damageModifier(normal_damage, targetStats, attackerStats)
    end

    local crit_chance = attackerStats.FullStats.CRITRATE
    local crit_dmg = attackerStats.FullStats.CRITDMG

    local crit, damage = StatFormula.RollCriticalChance(normal_damage, crit_chance, crit_dmg)

    return damage, crit
end

function CombatService:GetCombatData(player: Player)
    if player:IsDescendantOf(game.Players) then
        while not CombatData[player] do
            task.wait()
        end
        return CombatData[player]
    end
end

function CombatService:GetTagger(player)
    if CombatData[player] then
        return CombatData[player].Tagger
    end
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
