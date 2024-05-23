local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local States = {}

local Promise = require(ReplicatedStorage:WaitForChild("Utilities"):WaitForChild("Promise"))
local Priority = require(ReplicatedStorage.Utilities:WaitForChild"Priority")
local Trove = require(ReplicatedStorage.Packages.Trove)

local New = function(InstanceName, properties)
    local obj = Instance.new(InstanceName)
    for i,v in properties do
        obj[i] = v
    end    
    return obj
end
States.Attack = {
    Keys = {
        Enum.UserInputType.MouseButton1
    },
    Type = 'SinglePress',
    DelayAfter = 0.3,
    AcceptedRequestAmount = 4,
    CancelOnWeaponChange = true,
    CancelOnJump = true,
    Init = function(Character)
        Character.UserData.LastAttack = os.clock()
        Character.UserData.M1Timing = {}
    end,
    WeaponAnimationReset = function(Character, tracks)
        local M1Names = {'M1','M2','M3','M4','M5'}
        local M1Tracks = {}
        if tracks then
            for _, v in M1Names do
                if tracks[v] then
                    table.insert(M1Tracks, v)
                end
            end
        end

        Character.UserData.M1Tracks = M1Tracks
    end,
    Condition = function(Character)
        return #Character.UserData.M1Tracks > 0
    end,
    BeforeTrigger = function(Character)
        local t = Character.Cleaner:Extend()

        local walkspeed = Priority.Set(Character.Humanoid,'WalkSpeed',5,2)
        t:Add(walkspeed)

        return t
    end,
    AfterTrigger = function(_, t)
        if t then
            t:Destroy()    
        end
        
    end,
    Trigger = function(Character:{UserData:{}})

        local track:AnimationTrack
        return Promise.new(function(resolve)

            local userdata = Character.UserData
            local sequence = userdata.AttackSequence or 1
            local tracks = userdata.M1Tracks
            local timing = Character:GetWeaponTracks().Timing
            --debug mode
            -- if sequence == 1 then
            --     userdata.LastAttack = os.clock()    
            -- end
            -- userdata.M1Timing[sequence-1] = os.clock()-userdata.LastAttack
            if os.clock() - userdata.LastAttack > 1 then
                sequence = 1
            end
            userdata.LastAttack = os.clock()  

           -- walkspeed = Priority.Set(Character.Humanoid,'WalkSpeed',5,2)

            if sequence + 1 > #tracks then
                userdata.AttackSequence = 1
            else
                userdata.AttackSequence = sequence + 1
            end

            if tracks[sequence] then
                local t = timing.M1[sequence]
                track = Character:PlayWeaponTrack(tracks[sequence], 'Attack')
                track:AdjustSpeed(t[2])
                track.Priority =Enum.AnimationPriority.Action4

                task.wait(t[1]/t[2])
                Character:RefreshPlayingTracks()
                if sequence == #tracks then
                    Character:EndSimultaneousRequests()
                end
            end


            resolve()

        end):finally(function(status)
            -- if walkspeed then
            --     walkspeed:Dispose()
            -- end
            if status == 'Cancelled' then
                Character:StopTrack('Attack')    
            end
            
        end)
    end
}

States._character = {
    Keys = {},
    Init = function(self)
        local cleaner = self.Cleaner:Extend()

        local walkKeyBinds = {
            Forward = { Key = Enum.KeyCode.W, Direction = Enum.NormalId.Front },
            Backward = { Key = Enum.KeyCode.S, Direction = Enum.NormalId.Back },
            Left = { Key = Enum.KeyCode.A, Direction = Enum.NormalId.Left },
            Right = { Key = Enum.KeyCode.D, Direction = Enum.NormalId.Right }
        }

        local camera = workspace.CurrentCamera
        local character: Model = self.Character
        local root = character.HumanoidRootPart
        
        local function getWalkDirectionCameraSpace()
            local walkDir = Vector3.new()
        
            for _, keyBind in pairs(walkKeyBinds) do
                if UserInputService:IsKeyDown(keyBind.Key) then
                    walkDir += Vector3.FromNormalId( keyBind.Direction )
                end
            end
        
            if walkDir.Magnitude > 0 then --(0, 0, 0).Unit = NaN, do not want
                walkDir = walkDir.Unit --Normalize, because we (probably) changed an Axis so it's no longer a unit vector
            end
            
            return walkDir
        end
        
        local function getWalkDirectionWorldSpace()
            local walkDir = camera.CFrame:VectorToWorldSpace( getWalkDirectionCameraSpace() )
            walkDir *= Vector3.new(1, 0, 1) --Set Y axis to 0
        
            if walkDir.Magnitude > 0 then --(0, 0, 0).Unit = NaN, do not want
                walkDir = walkDir.Unit --Normalize, because we (probably) changed an Axis so it's no longer a unit vector
            end
        
            return walkDir
        end
        
        local targetMoveVelocity = Vector3.new()
        local moveVelocity = Vector3.new()
        local moveAcceleration = 8

        
        local function lerp(a,b,t)
            return a+(b-a)*t
        end
        local humanoid = self.Humanoid
        local function updateMovement( dt )
            
            if humanoid then
                local moveDir = getWalkDirectionWorldSpace()
                targetMoveVelocity = moveDir
                moveVelocity = lerp( moveVelocity, targetMoveVelocity, math.clamp(dt * moveAcceleration, 0, 1) )
                humanoid:Move( moveVelocity )
            end
        end	

        cleaner:Connect(RunService.RenderStepped, updateMovement)

        local tiltEnabled = true


        local lowerTorso = character.LowerTorso
        local root6D : Motor6D = lowerTorso.Root
        local defaultC1 = root6D.C1

        local tiltZ = 0
        local tiltX = 0

        cleaner:BindToRenderStep("CharacterTilt", Enum.RenderPriority.First.Value, function(dt)
            local ws = humanoid.WalkSpeed
            
            if not tiltEnabled then
                tiltZ, tiltX = 0, 0
            end
            if ws > 0 then
                local velocity = root.AssemblyLinearVelocity
                local movementVector = root.CFrame:vectorToObjectSpace(velocity/20)
                tiltZ = math.clamp(lerp(tiltZ, movementVector.X,dt ),-0.2,0.2)
                tiltX = math.clamp(lerp(tiltX, -movementVector.Z,dt),-0.2,0.2)
            else
                tiltZ = lerp(tiltZ, 0, 0.12)
                tiltX = lerp(tiltX, 0, 0.12)
            end
            root6D.C1 = defaultC1 * CFrame.Angles(tiltX,0,tiltZ)
        end)
    end
}

States.Busy = {
    Keys = {},
    Trigger = function(Character)
        local Value = Priority.Set(Character.Humanoid, 'WalkSpeed', 0, 1)
        return Promise.new(function()
            
        end):finally(function( )
            Value:Dispose()
        end)
    end,
    Disturbable = false
}

States.Sprint = {
    Keys = {
        Enum.KeyCode.LeftShift,
        Enum.KeyCode.RightShift
    },
    Type = 'Hold',
    Init = function(Character)
        
    end,
    Trigger = function(Character)

        local Value = Priority.Set(Character.Humanoid, 'WalkSpeed', 28, 2)
        local FOV = Priority.Set(workspace.CurrentCamera, 'FieldOfView', 85)

        return Promise.new(function()
            
        end):finally(function()
          --  print('Done running')
            FOV:Dispose()
           Value:Dispose()
        end)
    end
}

return States