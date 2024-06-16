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

local Mobs = {}

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

function Mob:UpdateCFrame()
    local root = self.Model:FindFirstChild('HumanoidRootPart')
    if root then
        TweenService:Create(root, INFO, {
            CFrame = self.CFrame
        }):Play()
    end
end


function Mob:Destroy()
    MobClient:RemoveMob(self.Model)
end

function MobClient:KnitStart()
    
end

function MobClient:GetMob(model: Model)
    if not model:IsDescendantOf(game) then return end
    if Mobs[model] then return Mobs[model] end

    local Cleaner = Trove.new()
    
    Mobs[model] = setmetatable({
        Model = model,
        Trove = Cleaner,
        --Streamable = streamable.primary(model)
    }, Mob)

    local self = Mobs[model]

    Cleaner:AttachToInstance(model)

    Cleaner:Add(function()
        Mobs[model] = nil
    end)

    print('New Mob:', model)

    return Mobs[model]
end

function MobClient:RemoveMob(model)
    if Mobs[model] then
        print('Removed Mob:', model)
        Mobs[model].Trove:Clean()
    end
end

function MobClient:KnitInit()
    packet.CFrame.listen(function(data)
        local self = MobClient:GetMob(data.Model)
        --print('Updating client mob', self)
        if self then
           

            local Model = data.Model
            local y = checkPositionRelativeToSurface(data.At, Model:GetChildren())
            y = y and y + 2.7 or data.At.Y
            
            local x,z = data.At.X, data.At.Z
            
            local CF = CFrame.lookAlong(
                Vector3.new(x,y,z),
                data.Direction
            )
            
            self.CFrame = CF    

            self:UpdateCFrame()
        end
    end)

    packet.Unrender.listen(function(model)
        --print(model, 'removing')
        local Mob = MobClient:GetMob(model)
        if Mob then
            Mob.Active = false    
        end
    end)

    packet.State.listen(function(data)
        local mob = MobClient:GetMob(data.Model)
        if mob then
            mob.State = data.State
 
        end
    end)

    packet.Render.listen(function(model)
        
        local Mob = MobClient:GetMob(model)
        if Mob then
            Mob.Active = true
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
                params.FilterDescendantsInstances = CollectionService:GetTagged('Mob')

                local parts = workspace:GetPartBoundsInRadius(pos, 40, params)
                for _, root in parts do
                    local Mob = MobClient:GetMob(root.Parent)
                    if Mob and not Mob.Active then
                        packet.Render.send (root.Parent)
                    end
                end
            end
        end)
        
    end)
    


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
