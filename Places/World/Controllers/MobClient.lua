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

function Mob:SetPosition(At, Direction, State, instant)
    --Direction = Direction or Vector3.zero

    local Model = self.Model
    local y = checkPositionRelativeToSurface(At, workspace.Mobs:GetChildren())
    y = y and y + Model.Humanoid.HipHeight or At.Y
    
    local x,z = At.X, At.Z
    
    local CF
    if Direction then
        CF = CFrame.lookAlong(
            Vector3.new(x,y,z),
            Direction * Vector3.new(1, 0.01, 1)
        )
    else
        CF = CFrame.new(x,y,z)
    end
    

    self.LastCFrameChange = os.clock()
    self.CFrame = CF    
    self:UpdateCFrame(instant)
    self:SetState(State)
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


       -- print('New State:', newState)

        
        self.State = newState
        self:UpdateAnimation()
    end
end

function Mob:Destroy()
    MobClient:RemoveMob(self.Model)
end

function MobClient:GetMob(model: Model)
    
    if not model or not model:IsDescendantOf(game) then return end
    if Mobs[model] then 
        
        
        Mobs[model]:SetState(model:GetAttribute('State'))    
        return Mobs[model] 
    end

    local Cleaner = Trove.new()
    
    Mobs[model] = setmetatable({
        Model = model,
        Trove = Cleaner,
        Module = mobs[model:GetAttribute('Module')],
        Tracks = {}
        --Streamable = streamable.primary(model)
    }, Mob)

    local self = Mobs[model]

    Cleaner:AttachToInstance(model)

    Cleaner:Add(function()
        Mobs[model] = nil
    end)
    self:SetState(model:GetAttribute('State'))    

    return Mobs[model]
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

    packet.Unrender.listen(function(model)
        --print(model, 'removing')
        local Mob = MobClient:GetMob(model)
        if Mob then
            Mob.Active = false    
            Mob:StopAllTracks()
            model.Parent = ReplicatedStorage.UnrenderedMobs
        end
    end)

    packet.State.listen(function(data)
        local mob = MobClient:GetMob(data.Model)
        if mob then
            mob:SetState(data.State)

        end
    end)

    packet.Render.listen(function(model)
        
        local Mob = MobClient:GetMob(model)
        if Mob then
            Mob.Active = true
            model.Parent = workspace.Mobs
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
                    local Model = root.Mob.Value

                    local mob = MobClient:GetMob(Model)
                    if mob and not mob.Active then

                        mob:SetPosition(root.Position, nil, Model:GetAttribute('State'), true)

                        packet.Render.send (Model)
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
end

return MobClient
