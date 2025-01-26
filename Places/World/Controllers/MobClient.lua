local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local TweenService = game:GetService("TweenService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local MobClient = Knit.CreateController { Name = "MobClient" }

local streamable = require(ReplicatedStorage.Packages.Streamable).Streamable

local Runtime = require(ReplicatedStorage.Utilities.Runtime)

local util = require(ReplicatedStorage.Utilities.Util)

local Trove = require(ReplicatedStorage.Packages.Trove)
local packet = require(ReplicatedStorage.Packets.Mob)
local player = game.Players.LocalPlayer

local mobs = require(ReplicatedStorage.GameModules.Mobs)

local ReplicaController = require(ReplicatedStorage.Madwork.ReplicaController)
local animations = ReplicatedStorage.Assets.NPCAnimations

local Mobs = {}

local MobReplicas = {}
local INFO = TweenInfo.new(0.4)
local function checkPositionRelativeToSurface(position, exclude)
    -- Define the starting point and direction for the raycast
    local rayOrigin = position
    local rayDirection = Vector3.new(0, -100, 0) -- Cast ray 100 studs downwards

    -- Define the raycast parameters (e.g., ignore specific parts or models if needed)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = exclude

    -- Perform the raycast
    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

    if raycastResult then
        -- If raycast hits something, get the Y level of the hit point
        return raycastResult.Position.Y
    else
        -- If raycast doesn't hit anything, consider it not above any surface
        return nil
    end
end

local Mob = {}
Mob.__index = Mob


function Mob.new()
    local self = setmetatable({}, Mob)
    return self
end

function Mob:UpdateCFrame(instant)
    local root = self.Model:FindFirstChild('HumanoidRootPart')
    if root then
      --  print(self.CFrame.Position.Y)
       -- root.CFrame = self.CFrame
       if self.Tween then
            self.Tween:Cancel()
        end

        --print('Setting cframe', self.CFrame)
       if not instant then
            local WS = self.Model.Humanoid.WalkSpeed
            local Distance = (root.Position - self.CFrame.Position).Magnitude
            local Duration = math.max(Distance/WS,0.1)

--            local Duration = 0.3

            local tween = TweenService:Create(root, TweenInfo.new(Duration, Enum.EasingStyle.Linear), {
                CFrame = self.CFrame
            })

            local track: AnimationTrack = self:GetAnimations().Running

            tween:Play()
            self.Tween = tween

        else
            root.CFrame = self.CFrame
       end
       
    end
end

function Mob:GetStats()
    return util.GetAsync(self, 'Stats', 'Mob Replica')
end

function Mob:SetPosition(At, Direction, State, instant, ForceDirection)
    --Direction = Direction or Vector3.zero

    local Model = self.Model
    local y = checkPositionRelativeToSurface(At, workspace.Mobs:GetChildren())
    y = y and y + Model.Humanoid.HipHeight or At.Y
    
    local x,z = At.X, At.Z
    
    local PrevPos = self.PrevPos

    local CF

    local DirectionCF = Direction and CFrame.lookAlong(
        Vector3.new(x,y,z),
        (Direction * Vector3.new(1, 0.0001, 1)).Unit
    )
    if ForceDirection and Direction then
        CF = DirectionCF
    end
    if (Model.HumanoidRootPart.Position - At).Magnitude > 3 then
        CF = CFrame.lookAlong(
            Vector3.new(x,y,z),
            ((At - Model.HumanoidRootPart.Position).Unit * Vector3.new(1, 0.0001, 1)).Unit
        )
    elseif Direction then
        CF = DirectionCF
    else
        CF = CFrame.new(x,y,z)
    end
    

    self.LastCFrameChange = os.clock()
    self.CFrame = CF    
    self:UpdateCFrame(instant)
    --self:SetState(self.State)
end

function Mob:GetAnimations()
    if self.Animations then
        return self.Animations
    end

    self.Animations = {}

    if self.Module.Animation then
        local folder = animations:FindFirstChild(self.Module.Animation)
        if folder then
            local humanoid = self.Model.Humanoid
            local animator: Animator = humanoid.Animator

            for _, v in folder:GetChildren() do
                self.Animations[v.Name] = animator:LoadAnimation(v)    
            end
        else
            warn('Unknown NPC Animation name:', self.Module.Animation, animations, animations.Parent)
        end
    end

    return self.Animations
end

function Mob:StopTrack(category)
    category = category or 'State'


    if self.Tracks[category] then
        self.Tracks[category]:Stop()
    end

    self.Tracks[category] = nil
end

function Mob:StopAllTracks()
    for category in self.Tracks do
        self:StopTrack(category)
    end
end

function Mob:PlayTrack(trackName, category)
    --print("playing animation:",trackName)
    category = category or 'State'
    self:StopTrack(category)

    local track = self:GetAnimations()[trackName]
    if track then
        self.Tracks[category] = track
        track:Play()
        --print(self.Tracks)
    end

    return track
end

function Mob:UpdateAnimation()
    self:PlayTrack(self.State)
end

function Mob:SetState(newState)
    if self.State ~= newState then


        --print('New State:', newState, '\n', debug.traceback())

        
        self.State = newState
        self:UpdateAnimation()
    end
end

function Mob:Destroy()
    MobClient:RemoveMob(self.Model)
end

function Mob:StopListeningMoveChanges()
    if self.MoveConnection then
        self.MoveConnection:Disconnect()
        self.MoveConnection = nil
    end
end

function Mob:ListenToMoveChanges()
    if not self.MoveConnection then
        local root = self.Root 
        self.MoveConnection = root:GetPropertyChangedSignal('CFrame'):Connect(function()
            --print((prev-root.Position).Magnitude, 'away')
            self:SetPosition(root.Position, root.CFrame.LookVector)
            
        end) 
    end
end

function MobClient:GetMob(root: Instance)
    
    if not root or not root:IsDescendantOf(game) then return end
    if Mobs[root] then 
        
        
        Mobs[root]:SetState(root:GetAttribute('State'))    
        return Mobs[root] 
    end

    local Cleaner = Trove.new()

    local Model: Model = ReplicatedStorage.Models:FindFirstChild(root.Name):Clone()
    Model.Parent = ReplicatedStorage.UnrenderedMobs
    Model.HumanoidRootPart.Anchored = true

    
    for _, v: Instance in Model:GetDescendants() do
        if v:IsA('BasePart') then
            v.CanCollide = false
        end
    end

    local Pointer = Instance.new('ObjectValue')
    Pointer.Value = root
    Pointer.Name = "RootPointer"
    Pointer.Parent = Model

    CollectionService:AddTag(Model.HumanoidRootPart, 'Entity')
    CollectionService:AddTag(Model.HumanoidRootPart, 'Mob')

    local humanoid: Humanoid = Model.Humanoid
    humanoid.NameDisplayDistance = 0
    humanoid.HealthDisplayDistance = 0

    local function UpdateHealth()
       
        humanoid.MaxHealth = root:GetAttribute('MaxHP')
        humanoid.Health = root:GetAttribute('HP') 
    end

    Model:SetAttribute("Level", root:GetAttribute('Level'))
    root:GetAttributeChangedSignal('HP'):Connect(UpdateHealth)
    root:GetAttributeChangedSignal('MaxHP'):Connect(UpdateHealth)


    UpdateHealth()

    Mobs[root] = setmetatable({
        Trove = Cleaner,
        Module = mobs[root:GetAttribute('Module')],
        Tracks = {},
        Model = Model,
        Root = root,
        --Streamable = streamable.primary(model)
    }, Mob)

    local self = Mobs[root]

    if self.Humanoid then
        for prop,value in self.Humanoid do
            Model.Humanoid[prop] = value
        end
    end

    self.PrevPos = root.Position


    local modelRoot: BasePart = Model.HumanoidRootPart
    local previousPos = modelRoot.Position
    local last = os.clock()

    local moving = false

    -- modelRoot:GetPropertyChangedSignal('Position'):Connect(function()
    --     local pos: Vector3 = modelRoot.Position
    --     local current = os.clock()
    --     local delta = (current - last)

    --     if delta > 0 then 
    --         local velocity = (pos - previousPos)/delta
    --         --print(velocity.Magnitude)
    --         if velocity.Magnitude > 0.05 then
    --             moving = true
                
    --         else
    --             moving = false
    --         end
    --         previousPos = pos 
    --     end

    --     if moving then
    --         local track = self:GetAnimations().Running
    --         track:Play()
    --     end

    --     last = current
    -- end)

    Cleaner:AttachToInstance(root)
    Cleaner:Add(Model)
    Cleaner:Add(function()
        Mobs[root] = nil
    end)
    self:SetState(root:GetAttribute('State'))    

    return Mobs[root]
end

function MobClient:RemoveMob(model)
    if Mobs[model] then
        --print('Removed Mob:', model)
        Mobs[model].Trove:Clean()
    end
end



function MobClient:KnitInit()

    packet.Animation.listen(function(data)
        local mob = MobClient:GetMob(data.Model)
        if mob then
            local track: AnimationTrack = mob:PlayTrack(data.Animation, data.Category or 'Action')
            
            if track then
                track.Priority = Enum.AnimationPriority.Action4
            end
        end
    end)

    packet.CFrame.listen(function(data)
        local self = MobClient:GetMob(data.Model)
        --print('Updating client mob', self)
        if self then
           self:SetPosition(data.At, data.Direction, data.State, data.Instant)
        end
    end)

    packet.Unrender.listen(function(root)
        --print(model, 'removing')
        local Mob = MobClient:GetMob(root)
        if Mob then
            Mob.Active = false    
            Mob:StopAllTracks()
            Mob.Model.Parent = ReplicatedStorage.UnrenderedMobs
            Mob:StopListeningMoveChanges()
        end
    end)

    packet.State.listen(function(data)
        local mob = MobClient:GetMob(data.Model)
        if mob then
            mob:SetState(data.State)

        end
    end)

    packet.Render.listen(function(root)
        
        local Mob = MobClient:GetMob(root)
        if Mob then
            Mob.Active = true
            Mob.Model.Parent = workspace.Mobs
            --Mob:SetPosition(root.Position, root.CFrame.LookVector, nil, true, true)
            Mob:ListenToMoveChanges()
        
            Mob:UpdateAnimation()
        end
        
        --MobClient:AddMob(model)
    end)
    local rs = nil
    util.CharacterAdded(player, function(char: Model)
        if rs then
            rs:Disconnect()
        end
        local params = OverlapParams.new()
        params.FilterType = Enum.RaycastFilterType.Include

        rs = RunService.RenderStepped:Connect(function()
            if os.clock() - (self.LastRender or 0) > 0.3 then
                self.LastRender = os.clock()
                local pos = char:GetPivot().Position
                params.FilterDescendantsInstances = CollectionService:GetTagged('MobPosition')

                local parts = workspace:GetPartBoundsInRadius(pos, 200, params)

                for _, root in parts do

                    local mob = MobClient:GetMob(root)
                    if mob and not mob.Active then

                        mob:SetPosition(root.Position, (nil), root:GetAttribute('State'), true)

                        packet.Render.send (root)
                    end
                    
                end

            end
        end)
        
    end, false)

    local runtimes = {}
    local p = {}
    local player = game.Players.LocalPlayer
    game:GetService("TextChatService").SendingMessage:Connect(function(message)
        local args = message.Text:split(" ")
       -- print(message.Text, args)
        if args[1] == 'rt' then
            local id = args[2]
            if not runtimes[id] then
                runtimes[id] = Runtime.new(player.Character:GetPivot().Position)
                runtimes[id].Trove:Add(function()
                    runtimes[id] = nil
                end)
                runtimes[id].Completed:Connect(function()
                    print('Finished playing')
                end)
                local part = p[id] or Instance.new('Part', workspace)
                part.Anchored = true
                part.CanCollide = false
                p[id] = part

                runtimes[id].Changed:Connect(function(pos, point)
                    part.CFrame = CFrame.new(pos, point)
                end)
            end
            if args[3] == 'newkf' then
                local timepos = runtimes[id].Duration + tonumber(args[4])
                runtimes[id]:AddKeyframe(timepos, player.Character:GetPivot().Position)
            elseif args[3] == 'play' then

                runtimes[id]:Play()
                
               

            elseif args[3] == 'pause' then
                runtimes[id]:Pause()
            elseif args[3] == 'timepos' then
                local timepos = tonumber(args[4])
                runtimes[id]:SetTimePosition(timepos)
            end
        end
    end)

    local SystemMonitor = Knit.GetController ('SystemMonitor')

    SystemMonitor.newAttributeTracker(workspace, 'MOB_PATHFINDING_FREQUENCY', function(value)
        return `Mob Pathfinding Calls: {value}/sec`
    end)
end

return MobClient
