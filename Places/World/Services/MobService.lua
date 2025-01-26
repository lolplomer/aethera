local VISIBLE_ROOT_PART = false

local CollectionService = game:GetService("CollectionService")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local MobModule = require(ReplicatedStorage.GameModules.Mobs)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Signal = require(ReplicatedStorage.Packages.Signal)

local Tagger = require(ReplicatedStorage.Utilities.Tagger)

local Model = ReplicatedStorage.Models

local Runtime = require(ReplicatedStorage.Utilities.Runtime)
local RateLimiter = require(ReplicatedStorage.Madwork.RateLimiter)
local FrequencyTracker = require(ReplicatedStorage.Utilities.FrequencyTracker)

local Path = PathfindingService:CreatePath {
    AgentCanJump = false,
    WaypointSpacing = 3
}
 
local MobService = Knit.CreateService {
    Name = "MobService",
    Client = {},
}

MobService.DebugMode = false
MobService.ActiveDistance = 300


local Mob = {}
Mob.__index = Mob

local MobFolder = Instance.new('Folder')
MobFolder.Parent = workspace
MobFolder.Name = 'Mobs'

local MobPosition = Instance.new('Folder')
MobPosition.Parent = workspace
MobPosition.Name = 'MobPosition'


local UnrenderedMobs = Instance.new('Folder')
UnrenderedMobs.Parent = ReplicatedStorage
UnrenderedMobs.Name = 'UnrenderedMobs'

local Mobs = {}

local packet = require(ReplicatedStorage.Packets.Mob)

local PathfindingFrequency = FrequencyTracker.new()

PathfindingFrequency:Watch(function(v)
    workspace:SetAttribute("MOB_PATHFINDING_FREQUENCY", v)
end)

local function new(name, props)
    local instance = Instance.new(name)
    for prop, value in props do
        instance[prop] = value
    end
    return instance
end

local function GetPositionAboveSurface(position)
    local result = workspace:Raycast(position, Vector3.new())
    if result and result.Instance then
        local part:Part = result.Instance
        local y = part.Position.Y + part.Size.Y/2
        return Vector3.new(position.X, y+1, position.Z), true
    end
    return position
end

function Mob.new(module, level, id, CF)
    local StatService = Knit.GetService('StatService')
    local modelTemplate:Model = Model:FindFirstChild(module.Model)
    if not modelTemplate then
        return warn('Unknown model',module.Model)
    end

  --  print('creating new mob')

    -- model = model:Clone()
   
    -- model:PivotTo(CF)
    -- model.Parent = UnrenderedMobs

    -- model.HumanoidRootPart.Anchored = true

    
    -- CollectionService:AddTag(model.HumanoidRootPart, 'Entity')
    -- CollectionService:AddTag(model.HumanoidRootPart, 'Mob')

    --local modelSize = model:GetExtentsSize()

    local Root = new('Part', {
        Size = Vector3.new(1,1,1),
        Anchored = true,
        Parent = workspace.Terrain,
        CanCollide = false,
        Material = 'Neon',
        Transparency = VISIBLE_ROOT_PART and 0.5 or 1,
        Name = module.Model
    })

    

    local self = setmetatable({
        _cleaner = Trove.new(),
        id = id,
        Stats = StatService:CreateMobStats(module.RawStats, level, Root),
       -- Model = model,
        Position = CF.Position,
        SpawnPosition = CF.Position,
        --Humanoid = model:WaitForChild('Humanoid'),
        Movement = Runtime.new(),
        CFrame = CF,
        Size = modelTemplate:GetExtentsSize(),
        --Root = model.HumanoidRootPart,
        Point = Vector3.new(),
        LookVector = Vector3.new(1,0,0),
        Active = false,
        Players = {},
        Seed = math.random(1,10000),
        Tagger = Tagger.forInstance(),
        Dead = false,
        Module = module,
    }, Mob)

    self._cleaner:Add(self.Stats)
    --self._cleaner:Add(self.Model)
    self._cleaner:Add(self.Movement)
    --self._cleaner:AttachToInstance(model)
    
    self.HealthChanged = self._cleaner:Construct(Signal)

    self._cleaner:Connect(self.HealthChanged, function(health)
        if health <= 0 and not self.Dead then
            self.Dead = true

            self:ChangeState()
            self.Movement:Stop()

            self.Root.CanQuery = false
            self.Root:SetAttribute('Dead', true)

            local Formula = require(ReplicatedStorage.Utilities.Misc.StatFormula)
            local RewardExp = Formula.GetRewardEXP(self.Stats.Level, module.Exp)

            self.Tagger:Distribute(function(playerCharacter: Player, scale: number)
                local player = game.Players:GetPlayerFromCharacter(playerCharacter)
                local exp = StatService:AddExp(player, RewardExp * scale)
                print(player, `got exp`, exp, `for killing`, modelTemplate, `{math.floor(scale*100)}% share`)
            end)

            -- Knit.GetService('EffectService'):SpawnEffect('Death', {
            --     Parent = self.Root
            -- })

            task.delay(3, self.Destroy, self)
        end
    end)

    -- self._cleaner:Add(function()
    --     if model.Parent then
    --         model:Destroy()
    --     end
    -- end)


    --new('ObjectValue', {Name = 'Mob', Parent = PositionPart, Value = model})

    self._cleaner:Add(Root)

    Root.Position = CF.Position

    CollectionService:AddTag(Root, 'MobPosition')

    self.PositionPart = Root
    self.Root = Root

    -- local _state = Enum.HumanoidStateType
    -- local exclude = {_state.Dead, _state.None}

    -- for _, state in Enum.HumanoidStateType:GetEnumItems() do
    --     if table.find(exclude, state) then continue end
    --     --print('disabling', state)
    --     self.Humanoid:SetStateEnabled(state, false)
    -- end


    self.Movement:SetWaitTime(0.1)

    self.Movement.Changed:Connect(function(position, point, name)

        --if self.Dead then return end

        if (point - position).Magnitude > 0 then
            self.LookVector = (point - position).Unit --* Vector3.new(1,0,1)
        end
        
        self.OnSpawnPoint = false
        self:ChangeState(name, false)

        --Root.CFrame = CFrame.lookAlong(position, self.LookVector)

        -- if MovementRateLimiter:CheckRate('Global') then
        --     self:SetPosition(position)  
        -- end
        self:SetPosition(position)  
    end)

    self.Movement.Completed:Connect(function()
        task.wait(0.1)
        if self.Movement.IsPlaying == false then
            self:ChangeState()    
        end
    end)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {MobPosition, CollectionService:GetTagged('Character')}

    self.RaycastParams = params

    self:InitiateStats()
    --self:InitiateHumanoid()
    self:ChangeState()
    --self:InitiateCollisions()
    self:InitiateActions()

    for prop, value in self.Module.Humanoid do
        self:Set(prop,value)
    end

    self.Root:SetAttribute('Module', module.Name)
    self.Root:SetAttribute('Level', level)

    Root.Parent = MobPosition
    return self
end

function Mob:Set(attribute, value)
    self.Root:SetAttribute(attribute, value)
end

function Mob:TakeDamage(value)
    self:SetHP(self:Get('HP') - value)
end

function Mob:SetHP(value)
    local max = self:Get("MaxHP")
    self:Set('HP', math.clamp(value, 0, max))
    self.HealthChanged:Fire(value, max)
end

function Mob:Get(attribute)
    return self.Root:GetAttribute(attribute)
end

--[[
function Mob:InitiateHumanoid()
    if self.Module.Humanoid then
        for property, value in self.Module.Humanoid do
            self.Humanoid[property] = value
        end

        self.Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
        self.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    end
end

function Mob:InitiateCollisions()
    for _, v: Instance in self.Model:GetDescendants() do
        if v:IsA('BasePart') then

            v.CanCollide = false
        end
    end
end
]]

function Mob:CastSingleTargetAttack(boxSize, length, desiredTarget, damageModifier)
    local size = Vector3.new(boxSize,boxSize,1)
    
    local params = RaycastParams.new()
    if desiredTarget then
        params.FilterType = Enum.RaycastFilterType.Include
        params.FilterDescendantsInstances = {desiredTarget.HumanoidRootPart}
    else
        params.FilterType =Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = CollectionService:GetTagged('Player')
    end

    local lookVector = self.LookVector
    if desiredTarget then
        lookVector = (desiredTarget:GetPivot().Position - self.Position).Unit
    end

    local raycastResult: RaycastResult = workspace:Blockcast(CFrame.lookAlong(self.Position, lookVector), size, lookVector * length, params)

    if raycastResult and raycastResult.Instance then
        local CombatService = Knit.GetService('CombatService')
        local TargetChar = raycastResult.Instance.Parent
        
        CombatService:DealDamage(TargetChar, self.Root, damageModifier)

        return raycastResult
    end
end

function Mob:InitiateStats()

    local function HealthChanged()
        local current, max = self:Get('HP'), self:Get('MaxHP')
        local scale = current and (current / max) or 1
        local HP = self.Stats:Get('HP')
        
        self:Set('MaxHP', HP)
        
        self:SetHP(HP * scale)
    end

    HealthChanged()

    self.Stats.Changed.HP:Connect(HealthChanged)
end

function Mob:ChangeState(newState, update)
    newState = newState or 'None'
    if self.State ~= newState then
        self.State = newState
        self.Root:SetAttribute('State', newState)

        if update ~= false then

            for player in self.Players do
                packet.State.sendTo({State = newState, Model = self.Root}, player)        
            end

            
        end
        
    end
end

function Mob:SetDirection(direction)
    self:SetPosition(nil, direction)
end

function Mob:SetPosition(position, direction, instant)
    self.Position = position or self.Position
    self.LookVector = direction or self.LookVector

    if instant then
        for player in self.Players do
            packet.CFrame.sendTo({
                At = self.Position,
                Direction = self.LookVector,
                Model = self.Root,
                State = self.State,
                Instant = instant
            }, player)
        end
    end

    self.Root.CFrame = CFrame.lookAlong(self.Position, self.LookVector)
end

function Mob:TeleportToSpawn()
    self.OnSpawnPoint = true
    self.Movement:Stop()
    self:ChangeState()
    self:SetPosition(self.SpawnPosition, nil, true)
   -- self:ChangeState()
   -- print(self.LookVector)
end

function Mob:Distance(position: Vector3)
    return (self.Position - position).Magnitude
end

function Mob:Direction(position)
    return (position - self.Position).Unit
end

function Mob:GetFirstPlayer(maxDistance)
    for player: Player, render in self.Players do
        if not render then continue end

        local Char = player.Character
        if Char and (self:Distance(Char:GetPivot().Position) < maxDistance) then
            if Char.Humanoid.Health > 0 then
                return player    
            end
        end
    end
end

function Mob:Destroy()
    self._cleaner:Destroy()
end
  
function Mob:UpdateParamsFilter()
	self.RaycastParams.FilterDescendantsInstances = {MobPosition, CollectionService:GetTagged('Character')}
end

function Mob:MoveTo(position: Vector3)
    if self.Dead then return end

    local _dist = (self.Position - position).Magnitude
    if _dist < 5 then return end

    local dir = (position - self.Position).Unit * (_dist)
    self:UpdateParamsFilter()
    local result = workspace:Blockcast(CFrame.new(self.Position), self.Size, dir, self.RaycastParams)
    print(result and result.Instance.Parent)
    if result and result.Instance then

        if self.Computing then return end
        
        if (os.clock()-(self.LastCompute or 0)) < 3 and self.PreviousPathStatus == Enum.PathStatus.Success then return end
        self.LastCompute = os.clock()

        local _pos = self.Position
        
        local success, e = pcall(function()
            self.Computing = true
            PathfindingFrequency:Tick()
            Path:ComputeAsync(_pos, position)
            self.Computing = false
        end)

        print('Computed Path')
    
        if success then
            if Path.Status == Enum.PathStatus.Success then
                local prev
                local keyframes = {
                    Runtime.newKeyframe(0, _pos)
                }
                local waypoints = Path:GetWaypoints()
                
                for _, waypoint in waypoints do
                    local dist
                    if not prev then
                        dist = (_pos - waypoint.Position).Magnitude
                    else
                        dist = (waypoint.Position - prev.Position).Magnitude
                    end
    
                    local duration = dist/self:Get('WalkSpeed')

                    local pos = waypoint.Position + Vector3.new(0,2.4,0)
    
                    local keyframe = Runtime.newKeyframe(keyframes[#keyframes][1] + duration, pos, 'Running')
                    table.insert(keyframes, keyframe)
    
                    prev = waypoint
                end
                
                self.Continuous = true
                self.Movement:ReplaceKeyframes(keyframes)
                self.Movement:Play()
            else
                if self.PreviousPathStatus ~= Enum.PathStatus.NoPath then
                    self.LastNoPathComputation = os.clock()
                elseif self.LastNoPathComputation and os.clock() - self.LastNoPathComputation > 4 then
                    self:TeleportToSpawn()
                end
            end
            self.PreviousPathStatus = Path.Status
        else
            warn(e)
        end

         
    else
        self.Continuous = false
        local dist = (self.Position - position).Magnitude
        local duration = dist/self:Get('WalkSpeed')
        local keyframes = {
            Runtime.newKeyframe(0, self.Position, 'Running'),
            Runtime.newKeyframe(duration, position, 'Running')
        }
        self.Movement:ReplaceKeyframes (keyframes)
        self.Movement:Play()
    end
 

    
end

function Mob:IsExist()
    --print(self.Model, self.Model and self.Model.Parent, self.Model and self.Model:IsDescendantOf(workspace))
    --return self.Model and self.Model:FindFirstChild('HumanoidRootPart')
    return self.Root:IsDescendantOf(workspace)
end

function Mob:PlayAnimation(name, category)
    for player in self.Players do
        packet.Animation.sendTo({
            Model = self.Root,
            Animation = name,
            Category = category
        }, player)
    end
end

function Mob:CheckActive()
    local Active = false

    if self:Distance(self.SpawnPosition) > 200 then
        return false
    end

    for player: Player in self.Players do
        if player.Character and (player.Character:GetPivot().Position - self.Position).Magnitude < MobService.ActiveDistance then
            Active = true
        else
            --print('unrendering on server...')
            packet.Unrender.sendTo(self.Root, player)
            self.Players[player] = nil
        end
    end

    return Active
end
function Mob:InitiateActions()
    self.Actions = {}
    self.Action = nil
    self.ActionInfo = {}
    self.ActionTrove = self._cleaner:Extend()

    self.CleanupAction = self.ActionTrove:WrapClean()

    if self.Module.Actions then
        for i, name in self.Module.Actions do
            local action = MobModule.Actions[name]
            if action then
                self.Actions[i] = action.Initiate(self)
                self.Actions[i].Name = name
            end

            self.ActionInfo[i] = {
                LastTrigger = 0
            }
        end
    end
end

function Mob:DispatchAction(i)
    
    
    self.CleanupAction()

    local actionInfo = self.ActionInfo[i]
    local action = self.Actions[i]

    local actionPromise = action.Trigger()
    actionInfo.LastTrigger = os.clock()
    self.ActionPromise = actionPromise
    self.Action = action.Name

    self.ActionTrove:Add(function()
        if actionPromise == self.ActionPromise then
            self.ActionPromise = nil
        end
        self.Action = nil
        if actionPromise.Status == 'Started' then
            actionPromise:cancel()    
        end
    end)

    actionPromise:finally(self.CleanupAction)
end
function Mob:Activate()
    if not self.Active then
        self.Active = self._cleaner:Extend()

        self.Active:Add(function()
            self.Target = nil
            self:TeleportToSpawn()

            for player in self.Players do
                packet.Unrender.sendTo(self.Root, player)
                self.Players[player] = nil
            end

            self.Active = nil
        end)

        self.Active:Connect(RunService.Stepped, function()
            if (os.clock() - (self.UpdateDelay or 0)) > 0.1 and self:IsExist() then
                self.UpdateDelay = os.clock()
                --print(self.Target, self.Players)

                if not self:CheckActive() and self.Active then
                    self.Active:Clean()
                    return
                end

                if self.Dead then return end

                if not self.Target then
                    self.Target = self:GetFirstPlayer(40)
                else
                    if self.Target.Character.Humanoid.Health <= 0 then
                        self.Target = nil
                        task.wait(1)
                        self:MoveTo(self.SpawnPosition)
                        return
                    end
                    local Pos = self.Target.Character:GetPivot().Position
                    
                    local distance = self:Distance(Pos)
                    if distance < 70 then

                        if not self.Action then
                            for i, action in self.Actions do
                                local actionInfo = self.ActionInfo[i]
                                if (os.clock() - actionInfo.LastTrigger) > (action.Cooldown or 1) then
                                    actionInfo.LastTrigger = os.clock()
                                    if not action.TargetMinimumDistance or distance <= action.TargetMinimumDistance then
                                        self:DispatchAction(i);
                                    end
                                end
                            end
                        end

                        if distance > 7 then
                            local lv = self:Direction(Pos)
                            local rv = lv:Cross(Vector3.new(0,1,0))
                            local pow = (math.noise(os.clock()/5,10,self.Seed) * 15)
                            self:MoveTo(Pos - lv * math.random(3,6) + rv * pow)
                        else
                            --actions
                            self:SetDirection(self:Direction(Pos))
                        end
                    
                        
                    else
                        if not self.OnSpawnPoint then
                            self:TeleportToSpawn()    
                        end
                        
                        self.Target = nil
                    end
                    
                end
                
            end
        end)
    end
end

local previous = 0
function MobService:Spawn(MobName, Level, CF)
    local module = MobModule[MobName]
    --print(module)
    if module then
        --print('spawning..',MobName)
        previous += 1
        local id = previous
        local mob = Mob.new(module, Level or 1, id, CF or CFrame.new())
      --  print(mob, Mob)
        mob._cleaner:Add(function()
            print('Mob Deleted')
            Mobs[mob.Root] = nil
        end)
        Mobs[mob.Root] = mob

        return mob
    end
end

function MobService:GetMobData(model)
    return Mobs[model]
end

function MobService:KnitStart()
    local playerDataService = Knit.GetService('PlayerDataService')
    playerDataService.PlayerAdded:Connect(function(player)
        player.Chatted:Connect(function(msg)
      --      print('mobserice',msg)
            local arg = msg:split(' ')
            if arg[1]=='spawn' then
                local mob = MobService:Spawn(arg[2],tonumber(arg[3]) or 1,player.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,-10))
                --print('Mob Data:', mob)
            end
        end)
    end)

    local mobSpawns = workspace:FindFirstChild('MobSpawns')
    if mobSpawns then
        for _, v in mobSpawns:GetChildren() do
            MobService:Spawn(v.Name, 1, v.CFrame)
        end    
    end
    
end

function MobService:KnitInit()
    packet.Render.listen(function(root, player: Player)
        local Mob = MobService:GetMobData(root)
        if not Mob then return end
        
        --print(Mob.Players[player], Mob.Players, Mob.Active)

        local Char = player.Character
        if Mob:Distance(Char:GetPivot().Position) < MobService.ActiveDistance then
            --print('Activating Mob', Mob.Active)

            packet.Render.sendTo(root, player)

            Mob.Players[player] = true
            Mob:Activate()
        end
    end)
end


return MobService
