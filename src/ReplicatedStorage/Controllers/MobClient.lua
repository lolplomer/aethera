local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local MobClient = Knit.CreateController { Name = "MobClient" }

local Runtime = require(ReplicatedStorage.Utilities.Runtime)
local ReplicaController = require(ReplicatedStorage.Madwork.ReplicaController)
local util = require(ReplicatedStorage.Utilities.Util)

local Mobs = {}

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

function MobClient:KnitStart()
    
end

function MobClient:KnitInit()

    ReplicaController.ReplicaOfClassCreated('Mob', function(replica)
        local Model : Model = replica.Tags.Model
        Model:WaitForChild('HumanoidRootPart')
        local Size = Model:GetExtentsSize()

        Mobs[Model] = {
            Replica = replica,
            Mover = Model:FindFirstChild('Mover') or util.new('LinearVelocity', {
                Parent = Model,
                MaxForce = 13000,
                RelativeTo = Enum.ActuatorRelativeTo.Attachment0,
                VelocityConstraintMode = Enum.VelocityConstraintMode.Vector,
                Attachment0 = util.new('Attachment', {Parent = Model.HumanoidRootPart}),
                Name = 'Mover'
            }),
            WaypointIndex = 2,
            Root = Model.HumanoidRootPart
        }
        local self = Mobs[Model]

        replica:ListenToChange('MovementKeyframes', function(value)
            self.WaypointIndex = 2
        end)

        local INFO = TweenInfo.new(0.4)
        replica:ListenToChange('CFrame', function(cf:CFrame)
            local y = checkPositionRelativeToSurface(cf.Position, Model:GetChildren())
            if y then
                y += 2.7
            end
            local x,_,z,_,_,R02,_,_,_,_,_,R22 = cf:GetComponents()

            TweenService:Create(self.Root, INFO, {
                CFrame = CFrame.lookAlong(
                    Vector3.new(x,y,z),
                    Vector3.new(-R02,0,-R22)
                )
            }):Play()
        end)

        replica:AddCleanupTask(function()
            Mobs[Model] = nil
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
