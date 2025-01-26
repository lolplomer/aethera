local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local States = {}

local Knit = require(ReplicatedStorage.Packages.Knit)

local Promise = require(ReplicatedStorage:WaitForChild("Utilities"):WaitForChild("Promise"))
local Priority = require(ReplicatedStorage.Utilities.Priority)
local Trove = require(ReplicatedStorage.Packages.Trove)

local Util = require(ReplicatedStorage.Utilities.Util)

local NO_ACTION = function()end

States.Attack = {
    Keys = {
        Enum.UserInputType.MouseButton1
    },
    Type = 'SinglePress',
    DelayAfter = 0.3,
    AcceptedRequestAmount = 4,
    CancelOnWeaponChange = true,
    CancelOnJump = true,
    MobileButton = {
        Icon = "",
        Position = UDim2.fromScale(1, 0.5),
        AnchorPoint = Vector2.new(1, 0.5)
    },
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
        local cancelled = false

        local ShakeController =  Knit.GetController('ShakeController')
        return Promise.new(function(resolve)

            local userdata = Character.UserData
            local sequence = userdata.AttackSequence or 1
            local tracks = userdata.M1Tracks
            local timing = Character:GetWeaponTracks().Timing
            if os.clock() - userdata.LastAttack > 1 then
                sequence = 1
            end
            userdata.LastAttack = os.clock()  
            if sequence + 1 > #tracks then
                userdata.AttackSequence = 1
            else
                userdata.AttackSequence = sequence + 1
            end

            if tracks[sequence] then
                local t = timing.M1[sequence]
                track = Character:PlayWeaponTrack(tracks[sequence], 'Action')
                track:AdjustSpeed(t[2])
                track.Priority =Enum.AnimationPriority.Action4

                task.delay(0.2, function()
                    if not cancelled then
                        Knit.GetController('CharacterController'):CastNormalAttack()
                    end
                end)

                if t[3] == 'lunge' then
                    task.delay(t[4] or 0, function()
                        ShakeController:Start("Lunge")
                        if cancelled then return end
                        Knit.GetController('EffectClient'):SpawnEffect('Lunge', {
                            CFrame = Character.Root.CFrame * CFrame.new(-1, 0, 3.2),
                            Parent = Character.Root
                        })
                    end)
                elseif t[3] then
                    task.delay(t[6] or 0, function()
                        --ShakeController:Start(t[3] and "SwingLeft" or "SwingRight")
                        if cancelled then return end
                        Knit.GetController('EffectClient'):SpawnEffect('Slash-02', {
                            Parent = Character.Root,
                            CFrame = Character.Root.CFrame,
                            Bool1 = t[4],
                            Number1 = t[3],
                            Number2 = t[5]
                        })
                    end)
                end

                task.wait(t[1]/t[2])
                Character:RefreshPlayingTracks()
                if sequence == #tracks then
                    Character:EndSimultaneousRequests()
                end
            end


            resolve()

        end):finally(function(status)
            if status == 'Cancelled' then
                cancelled = true
                Character:StopTrack('Action')    
            end
            
        end)
    end
}

States._character = {
    Keys = {},
    Init = function(self)
        local cleaner = self.Cleaner:Extend()
        
        local function lerp(a,b,t)
            return a+(b-a)*t
        end
         local humanoid:Humanoid = self.Humanoid

        local tiltEnabled = true

        local character: Model = self.Character
        local root = character.HumanoidRootPart

        local lowerTorso = character.LowerTorso
        local root6D : Motor6D = lowerTorso.Root
        local defaultC1 = root6D.C1

        local tiltZ = 0
        local tiltX = 0
        local ShakeController =  Knit.GetController('ShakeController')
        local lastHealth = humanoid.Health
        cleaner:Connect(humanoid.HealthChanged, function(health)
            if health < lastHealth then
                ShakeController:Start(math.random(1,2)==1 and "Hit1" or "Hit2")
            end
        end)

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

        humanoid.AutoRotate = false

        cleaner:Connect(humanoid:GetPropertyChangedSignal("AutoRotate"), function()
            if humanoid.AutoRotate == true then
                warn("Humanoid AutoRotate is Disabled. Please instead use CharacterController:GetCharacter().Props.AutoRotate")
            humanoid.AutoRotate = false
            end
            
        end)

        local MouseLockController = Knit.GetController("MouseLockController")
        local LoadingController = Knit.GetController('LoadingController')

        local function GetCameraLookVector()
            local CameraCF: CFrame = workspace.CurrentCamera.CFrame
    
            return -CameraCF.RightVector:Cross(Vector3.yAxis)
        end

        local function Look()
            return CFrame.lookAlong(root.Position, GetCameraLookVector())
        end

        local Orientation:AlignOrientation = self:AlignOrientation(Look())
        Orientation.Responsiveness = 40


        cleaner:Connect(RunService.RenderStepped, function(dt)
            self.Character:SetAttribute("AutoRotate",self.Props.AutoRotate:Get())
            Orientation.Enabled = self.Props.AutoRotate:Get() 

            if Orientation.Enabled then
                local MoveDir = humanoid.MoveDirection
                if MouseLockController:GetIsMouseLocked() == true or LoadingController.Enabled then                    
                    Orientation.CFrame = Look()    
                elseif MoveDir.Magnitude > 0 then
                    Orientation.CFrame = Orientation.CFrame:Lerp(CFrame.lookAlong(root.Position,MoveDir), .3)
                    
                end

            end
            
        end)

        print(self.Props, self.Props.AutoRotate._instance)

    end
}

States.Busy = {
    Keys = {},
    Trigger = function(Character)
        local WalkSpeed = Priority.Set(Character.Humanoid, 'WalkSpeed', 0, 0)
        local JumpPower = Priority.Set(Character.Humanoid, 'JumpPower', 0, 0)

        return Promise.new(NO_ACTION):finally(function( )
            WalkSpeed:Dispose()
            JumpPower:Dispose()
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
    DelayAfter = 0.1,
    Condition = function(Character)
        return (Character.Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall) and (Character.Stamina >= 10)
    end,    
    Trigger = function(Character)

        local StatsClient = Knit.GetController('StatsClient')
        local ShakeController =  Knit.GetController('ShakeController')
        local MOVSPD = StatsClient:Get('MOVSPD')
        local Value = Priority.Set(Character.Humanoid, 'WalkSpeed', 28 * MOVSPD, 1)
        local FOV = Priority.Set(workspace.CurrentCamera, 'FieldOfView', 85)

        --local AutoRotate = Character.PriorityHumanoid:Add('AutoRotate',false,1)
        local AutoRotate = Character.Props.AutoRotate:Add(false)
        --warn("SPRINT AUTOROTATE:",AutoRotate:GetValue())
        local Dash = Character:PlayTrack('Dash', 'Action')
        local Run: AnimationTrack = Character:GetTrack('Run')
        local Time = .15
        local humanoid: Humanoid = Character.Humanoid

        local Mover, Rotater = nil, nil
        local Done = false

        local State = 'Sprint'

        if Character._runTrove then
            Character._runTrove:Destroy()
        end

        local _runTrove = Trove.new()
        Character._runTrove = _runTrove

        _runTrove:Add(function()
            
            ShakeController:Stop('Running')
            
            Run:Stop()
            AutoRotate:Dispose()
            --Dash:Stop()
            FOV:Dispose()
            Value:Dispose()

            Character._runTrove = nil

            Mover:Destroy()

            --humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        end)

        local cleanup = _runTrove:WrapClean()

        return Promise.new(function()


            local movedir = Character.Humanoid.MoveDirection
        
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
            --humanoid.AutoRotate = false

            local dir = humanoid.MoveDirection

            if movedir.Magnitude == 0 then
                dir = Character.Root.CFrame.LookVector
            end

            local raycastResult: RaycastResult = Character:Raycast(Vector3.new(0, -10, 0))
            if raycastResult then
                local upVector = raycastResult.Normal
                local rightVector = workspace.CurrentCamera.CFrame.RightVector
                local moveVector = Character:GetMoveVector()
                if moveVector.Magnitude == 0 then
                    moveVector = Vector3.new(0, 0, -1)
                end

                dir = rightVector:Cross(upVector) * moveVector.Z + rightVector * moveVector.X
            end

            Mover = Character:AddVelocity(dir * 100 * MOVSPD,Time)
            
            Rotater = Character:AlignOrientation(CFrame.lookAlong(Character.Root.Position, dir), Time + 0.2)

            task.delay(Time, function()
                if not Done then
                    
                    

                    if Character:IsMoving() then
                        if humanoid:GetState() == Enum.HumanoidStateType.Running then
                            Run:Play()    
                            ShakeController:Start("Running")
                        end
                    else
                        Character:CancelAction(State)
                    end
                    
                    Run.Looped = true
                    Run:AdjustSpeed(1.25 * MOVSPD)
                    Run.Priority = Enum.AnimationPriority.Movement

                    _runTrove:Connect(humanoid.StateChanged, function(_, new)
                        if Done or Character.State ~= 'Sprint' then
                            return _runTrove:Destroy()
                        end
                        if new == Enum.HumanoidStateType.Freefall then
                            
                            ShakeController:Stop('Running')
                            Run:Stop()
                        elseif new ==  Enum.HumanoidStateType.Landed then
                            Run:Play()
                    
                            ShakeController:Start('Running')
                            Run:AdjustSpeed(1.25 * MOVSPD)
                        end
                    end)
                    
                    _runTrove:Connect(humanoid.Running, function(speed)
                        if speed == 0 then
                            Run:Stop()
                            Character:CancelAction(State)
                        end
                    end)
                end

                task.wait(.15)

                AutoRotate:Dispose()
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
            end)

            local effect = Knit.GetController('EffectClient')

            effect:SpawnEffect('Wind-02', {
                CFrame = Character.Root.CFrame * CFrame.new(0, 2.4, 0),
                Parent = Character.Root,
                Emit = 10,
            })

            Character:CooldownState(.5, 'Sprint')

            Character:AddStamina(-10)

            task.delay(0, function()
                while not Done and Character.Stamina > 0 and Character:IsActive() do
                    Character:AddStamina(-1)
                    task.wait(0.15)
                end
                if not Done and Character.Stamina <= 0 and Character:IsActive() then
                    Character:CancelAction(State)
                end
            end)

            
            
        end):finally(function()
            Done = true
            cleanup()
        end)
    end
}

return States