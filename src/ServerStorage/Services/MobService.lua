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
    WaypointSpacing = 7
}

local MobService = Knit.CreateService {
    Name = "MobService",
    Client = {},
}

local TWINFO = TweenInfo.new(0.677)

local Mob = {}
Mob.__index = Mob

local MobFolder = Instance.new('Folder')
MobFolder.Parent = workspace
MobFolder.Name = 'Mobs'

local Mobs = {}


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
    model.Parent = MobFolder
    model:PivotTo(CF)

    model.HumanoidRootPart.Anchored = true
    local root: BasePart = model.HumanoidRootPart
    --root:SetNetworkOwner(game.Players.Firzal_VX)
    CollectionService:AddTag(model.HumanoidRootPart, 'Entity')

    local modelSize = model:GetExtentsSize()

    local self = setmetatable({
        _cleaner = Trove.new(),
        id = id,
        Stats = StatService:CreateMobStats(module.RawStats, level),
        Model = model,
        Position = CF.Position,
        SpawnPosition = CF.Position,
        Movement = Runtime.new(),
        WalkSpeed = 16,
        CFrame = CF,
        Size = modelSize,
        Root = model.HumanoidRootPart,
        Point = Vector3.new(),
        Replica = ReplicaService.NewReplica {
            ClassToken = MobToken,
            Data = {MovementKeyframes = {}, Position = {CF.Position,Vector3.zero}},
            Tags = {Model = model},
            Replication = 'All'
        }
    }, Mob)

    self._cleaner:Add(self.Stats)
    self._cleaner:Add(self.Model)
    self._cleaner:Add(self.Movement)
    self._cleaner:Connect(model.AncestryChanged, function()
        if not model.Parent then
            self:Destroy()
        end
    end)
    self._cleaner:Add(self.Replica)

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

    

    self.Movement.Changed:Connect(function(position, point)

 
        local _pos = self.Position

        self.Position = position
        local cf
        if (position-point).Magnitude > 0 then
            cf = CFrame.new(position, point) 
        else
            cf = CFrame.new(position)
        end
        self.Point = point
        self.CFrame = cf

        debug.Position = position

        self.Replica:SetValue('CFrame', cf)
    end)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = self.Model:GetChildren()

    self.RaycastParams = params

    return self
end

function Mob:TeleportToSpawn()
    self.Movement:Stop()
    self.Position = self.SpawnPosition
    self.Replica:SetValue('CFrame', CFrame.new())
end


function Mob:Destroy()
    self._cleaner:Destroy()
end

function Mob:MoveTo(position: Vector3)

    --local position, collisionDetect = GetPositionAboveSurface(position)

    local dist = (self.Position - position).Magnitude
    if dist < 5 then return end

    local origin = self.Position

    local dir = (position - self.Position).Unit * (dist - 3)
    local result = workspace:Blockcast(CFrame.new(self.Position), self.Size, dir, self.RaycastParams)
    --print(result)
  --  result = {Instance = true}

    if result and result.Instance then

        if self.Computing then return end
        
        if (os.clock()-(self.LastCompute or 0)) < 1 then return end
        self.LastCompute = os.clock()

        local _pos = self.Position
        
        local success, e = pcall(function()
            local id = math.random(1,1000)
            local s = os.clock()
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
                
                for _ = 1,1 do
                    table.remove(waypoints, 1)    
                end
                
                for _, waypoint in waypoints do
                    local dist
                    if not prev then
                        dist = (_pos - waypoint.Position).Magnitude
                    else
                        dist = (waypoint.Position - prev.Position).Magnitude
                    end
    
                    local duration = dist/self.WalkSpeed

                    local pos = waypoint.Position + Vector3.new(0,2.4,0)
    
                    local keyframe = Runtime.newKeyframe(keyframes[#keyframes][1] + duration, pos)
                    table.insert(keyframes, keyframe)
    
                    prev = waypoint
                end
                
                self.Continuous = true
                self.Replica:SetValue('MovementKeyframes', keyframes)
                self.Movement:ReplaceKeyframes(keyframes)
                self.Movement:Play()
                

                return 'Pathfinding MoveTo', result
            elseif self.PreviousPathStatus ~= Enum.PathStatus.NoPath then
                self.LastNoPathComputation = os.clock()
            elseif self.LastNoPathComputation and os.clock() - self.LastNoPathComputation > 4 then
                self.LastNoPathComputation = os.clock()
                print('NO PATH AVAILABLE')
                self:TeleportToSpawn()
            end
            self.PreviousPathStatus = Path.Status
            return Path.Status, result
        else
            warn(e)
        end

        
    else
        self.Continuous = false
        local dist = (self.Position - position).Magnitude
        local duration = dist/self.WalkSpeed
        local keyframes = {
            Runtime.newKeyframe(0, self.Position),
            Runtime.newKeyframe(duration, position)
        }
        self.Replica:SetValue('MovementKeyframes', keyframes)
        self.Movement:ReplaceKeyframes (keyframes)
        self.Movement:Play()

        return 'Direct MoveTo', result
    end
 

    
end

local previous = 0
function MobService:Spawn(MobName, Level, CF)
    local module = MobModule[MobName]
    print(module)
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
                while true do
                    --debug.profilebegin('MobMoveTo')
                    
                    local a = os.clock()
                    local charpos = player.Character.HumanoidRootPart.Position
                    if (mob.Position-charpos).Magnitude > 7 then
                        
                        local pos = charpos - (charpos - mob.Position).Unit * 5
                        local type,r,collisionDetect = mob:MoveTo(pos)    
                        --print(os.clock() - a, collisionDetect and "COLLISION_DETECT" or 'noCollision', type,r)
                    end
                    
                    --
            
                    --debug.profileend()
                    task.wait(.1)
                end
                print('Mob Data:', mob)
            end
        end)
    end)
end

function MobService:KnitInit()
    
end


return MobService
