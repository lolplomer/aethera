local CollectionService = game:GetService("CollectionService")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local MobModule = require(ReplicatedStorage.GameModules.Mobs)
local Trove = require(ReplicatedStorage.Packages.Trove)

local ReplicaService = require(ServerScriptService.ReplicaService)
local MobToken = ReplicaService.NewClassToken('Mob')

local Model = ReplicatedStorage.Models

local Runtime = require(ReplicatedStorage.Utilities.Runtime)

local Path = PathfindingService:CreatePath {
    AgentCanJump = false,
    WaypointSpacing = 3
}
 
local MobService = Knit.CreateService {
    Name = "MobService",
    Client = {},
}

MobService.DebugMode = false
MobService.ActiveDistance = 100

local TWINFO = TweenInfo.new(0.677)

local Mob = {}
Mob.__index = Mob

local MobFolder = Instance.new('Folder')
MobFolder.Parent = workspace
MobFolder.Name = 'Mobs'

local Mobs = {}

local packet = require(ReplicatedStorage.Packets.Mob)

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
    local model:Model = Model:FindFirstChild(module.Model)
    if not model then
        return warn('Unknown model',module.Model)
    end

    model = model:Clone()
   
    model:PivotTo(CF)
    model.Parent = MobFolder

    model.HumanoidRootPart.Anchored = true
    --root:SetNetworkOwner(game.Players.Firzal_VX)
    CollectionService:AddTag(model.HumanoidRootPart, 'Entity')
    CollectionService:AddTag(model.HumanoidRootPart, 'Mob')

    local modelSize = model:GetExtentsSize()

    local self = setmetatable({
        _cleaner = Trove.new(),
        id = id,
        Stats = StatService:CreateMobStats(module.RawStats, level),
        Model = model,
        Position = CF.Position,
        SpawnPosition = CF.Position,
        Humanoid = model:WaitForChild('Humanoid'),
        Movement = Runtime.new(),
        WalkSpeed = 16,
        CFrame = CF,
        Size = modelSize,
        Root = model.HumanoidRootPart,
        Point = Vector3.new(),
        LookVector = Vector3.new(),
        Active = false,
        Players = {},
        Seed = math.random(1,10000)
    }, Mob)

    self._cleaner:Add(self.Stats)
    self._cleaner:Add(self.Model)
    self._cleaner:Add(self.Movement)
    self._cleaner:Connect(model.AncestryChanged, function()
        if not model.Parent then
            self:Destroy()
        end
    end)
    self._cleaner:Connect(self.Humanoid.Died, function()
        self:Destroy()
    end)
    self._cleaner:Add(function()
        if model.Parent then
            model:Destroy()
        end
    end)

    if MobService.DebugMode then
        local debug = new('Part', {
            Size = Vector3.new(2,2,2),
            Anchored = true,
            Parent = workspace.Terrain,
            CanCollide = false,
            CanQuery = false,
            CanTouch = false,
            Material = 'Neon',
            Transparency = 0.6
        })
    
        self.DebugPart = debug
    end


    self.Movement.Changed:Connect(function(position, point, name)
        if (point - position).Magnitude > 0 then
            self.LookVector = (point - position).Unit --* Vector3.new(1,0,1)
        end

        self:ChangeState(name)
        
        self:SetPosition(position)
    end)

    self.Movement.Completed:Connect(function()
        --print('Move completed')
        self:ChangeState()
    end)


    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = self.Model:GetChildren()

    self.RaycastParams = params


    --packet.Unrender.sendToAll(model)
    print('Setting initial client position')
    --self:SetPosition()

    return self
end

function Mob:ChangeState(newState)
    newState = newState or 'None'
    if self.State ~= newState then
        self.State = newState
        packet.State.sendToAll({State = newState, Model = self.Model})
    end
end

function Mob:SetDirection(direction)
    self:SetPosition(nil, direction)
end

function Mob:SetPosition(position, direction)
    self.Position = position or self.Position
    self.LookVector = direction or self.LookVector

    packet.CFrame.sendToAll({
        At = self.Position,
        Direction = self.LookVector,
        Model = self.Model
    })
    

    if self.DebugPart then
        self.DebugPart.CFrame = CFrame.lookAlong(self.Position, self.LookVector)
    end
end

function Mob:TeleportToSpawn()
    self.Movement:Stop()
    self:SetPosition(self.SpawnPosition)
    self:ChangeState()
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
            return player
        end
    end
end

function Mob:Destroy()
    self._cleaner:Destroy()
end

function Mob:MoveTo(position: Vector3)

    local _dist = (self.Position - position).Magnitude
    if _dist < 5 then return end

    local dir = (position - self.Position).Unit * (_dist - 3)
    local result = workspace:Blockcast(CFrame.new(self.Position), self.Size, dir, self.RaycastParams)
    if result and result.Instance then

        if self.Computing then return end
        
        if (os.clock()-(self.LastCompute or 0)) < 3 and self.PreviousPathStatus == Enum.PathStatus.Success then return end
        self.LastCompute = os.clock()

        local _pos = self.Position
        
        local success, e = pcall(function()
            self.Computing = true
            Path:ComputeAsync(_pos, position)
            self.Computing = false
        end)
    
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
    
                    local duration = dist/self.WalkSpeed

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
        local duration = dist/self.WalkSpeed
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
    return self.Model and self.Model:IsDescendantOf(workspace)
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
            packet.Unrender.sendTo(self.Model, player)
            self.Players[player] = nil
        end
    end

    return Active
end

function Mob:Activate()
    if not self.Active then
        self.Active = self._cleaner:Extend()

        self.Active:Add(function()
            self.Target = nil
            self:TeleportToSpawn()

            for player in self.Players do
                packet.Unrender.sendTo(self.Model, player)
                self.Players[player] = nil
            end

            self.Active = nil
        end)

        self.Active:Connect(RunService.Stepped, function()
            if (os.clock() - (self.UpdateDelay or 0)) > 0.02 and self:IsExist() then
                self.UpdateDelay = os.clock()


                --print(self.Target, self.Players)

                if not self:CheckActive() and self.Active then
                    self.Active:Clean()
                    return
                end


                if not self.Target then
                    self.Target = self:GetFirstPlayer(40)
                else
                    local Pos = self.Target.Character:GetPivot().Position
                    

                    local distance = self:Distance(Pos)
                    if distance < 40 then

                        if distance > 14 then
                            local lv = self:Direction(Pos)
                            local rv = lv:Cross(Vector3.new(0,1,0))
                            local pow = (math.noise(os.clock()/5,10,self.Seed) * 20)
                            self:MoveTo(Pos - lv * math.random(5,14) + rv * pow)
                        else
                            --actions
                            self:SetDirection(self:Direction(Pos))
                        end
                    
                        
                    else
                        self:TeleportToSpawn()
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
        print('spawning..',MobName)
        previous += 1
        local id = previous
        local mob = Mob.new(module, Level or 1, id, CF or CFrame.new())
        mob._cleaner:Add(function()
            print('Mob Deleted')
            Mobs[mob.Model] = nil
        end)
        Mobs[mob.Model] = mob

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
                local mob = MobService:Spawn(arg[2],1,player.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,-10))
                print('Mob Data:', mob)
            end
        end)
    end)

    for _, v in workspace.MobSpawns:GetChildren() do
        MobService:Spawn(v.Name, 1, v.CFrame)
    end
end

function MobService:KnitInit()
    packet.Render.listen(function(model, player: Player)
        local Mob = MobService:GetMobData(model)
        if not Mob then return end
        
        print(Mob.Players[player], Mob.Players, Mob.Active)

        local Char = player.Character
        if Mob:Distance(Char:GetPivot().Position) < MobService.ActiveDistance then
            print('Activating Mob', Mob.Active)

            packet.Render.sendTo(model, player)

            Mob.Players[player] = true
            Mob:Activate()
        end
    end)
end


return MobService
