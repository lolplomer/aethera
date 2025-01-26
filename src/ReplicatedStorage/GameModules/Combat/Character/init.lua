local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")
local Packages = ReplicatedStorage:WaitForChild"Packages"
local Trove = require(Packages:WaitForChild"Trove")
local BridgeNet2 = require(Packages:WaitForChild("bridgenet2"))

local utility = ReplicatedStorage:WaitForChild'Utilities'
local Promise = require(utility:WaitForChild'Promise')

local Knit = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Knit'))

local GameModules = ReplicatedStorage:WaitForChild"GameModules"
local CombatFolder = GameModules:WaitForChild("Combat")
local States = require(CombatFolder:WaitForChild("States"))

local Util = require(ReplicatedStorage:WaitForChild("Utilities"):WaitForChild"Util")
local Priority = require(ReplicatedStorage.Utilities:WaitForChild"Priority")

local signal = require(ReplicatedStorage:WaitForChild'Packages':WaitForChild'Signal')

local Items = require(GameModules.Items)

local player = game.Players.LocalPlayer
local ControlModule = require(player.PlayerScripts:WaitForChild('PlayerModule'):WaitForChild('ControlModule'))
local spring = require(ReplicatedStorage.Utilities.spring)

local Gizmo = require(Packages.imgizmo)
local Module = {}

local CharacterClass = {}
CharacterClass.__index = CharacterClass

local StateChanged = BridgeNet2.ReferenceBridge("StateChanged")

local DEFAULT_WALKSPEED = StarterPlayer.CharacterWalkSpeed
local DEFAULT_JUMP_POWER = StarterPlayer.CharacterJumpPower

local CombatService

function CharacterClass:SetState(State, index)
    self.State = State
    self.StateIndex = index


    CombatService:SetState(State, index)
    self.StateChanged:Fire(State, index)
    --StateChanged:Fire {State, index}
end

function CharacterClass:SetAwaitingState(State, Index)
    self.AwaitingStates.State = State
    self.AwaitingStates.StateIndex = Index
end

function CharacterClass:GetWeaponTracks()
    return self.Tracks[self.WeaponSubtype]
end

function CharacterClass:GetAnimationTracks(Name, Source:Folder)

    if self.Tracks[Name] then
        return self.Tracks[Name]
    end

    if Source then
        self.Tracks[Name] = {}
        for _, animation in Source:GetChildren() do
            if animation:IsA('Animation') then
                self.Tracks[Name][animation.Name] = self.Animator:LoadAnimation(animation)                
            elseif animation:IsA('ModuleScript') then
                self.Tracks[Name][animation.Name] = require(animation)
            end
        end
        return self.Tracks[Name]
    end
end

function CharacterClass:ResetWeaponAnimations()
    
    if self.AnimTrove then
        self.AnimTrove:Destroy()
    end

    local AnimTrove = self.Cleaner:Extend("AnimationTrove")

    AnimTrove:Add(function()
        self.AnimTrove = nil
        self:StopTrack()
    end)

    local Weapon = self.Weapon
    local Subtype = nil
    if Weapon.Data then

        Subtype = Weapon.Info.Equipment.Subtype
        local Folder = Util.GetWeaponFolder(Subtype )
        local AnimationFolder = Util.GetAnimationFolder(Folder, 'Default')

        self:GetAnimationTracks(Subtype, AnimationFolder)
    end

    self.WeaponSubtype = Subtype

    
    self.AnimTrove = AnimTrove


    for _,v in States do
        if v.WeaponAnimationReset then
            v.WeaponAnimationReset(self, self:GetWeaponTracks())
        end
    end

    if self.State and States[self.State].CancelOnWeaponChange then
        self:CancelAction()
    end

    --task.delay(0.04, self.RefreshPlayingTracks, self)
    self:RefreshPlayingTracks()
end

function CharacterClass:IsMoving()
    return self.Humanoid.MoveDirection.Magnitude > 0;
end

function CharacterClass:RefreshPlayingTracks()
    self:PlayWeaponTrack(self:IsMoving() and 'Running' or 'Idle', nil, true)
end

function CharacterClass:SetupAnimations()
    local InvController = Knit.GetController('InventoryController')

    self.Cleaner:Add(
        InvController:ListenOnEquipmentSwitch('Weapon', function(item, position, itemInfo)
        --    print('Weapon Changed:', item, position, itemInfo)

            self.Weapon.Id = item and item[3]
            self.Weapon.Data = item
            self.Weapon.Info = itemInfo

            self:ResetWeaponAnimations()
        end)
    )

    local Humanoid: Humanoid = self.Humanoid

    self.Cleaner:Connect(Humanoid.Running, function(speed)
        self:PlayWeaponTrack(speed > 0 and 'Running' or 'Idle', nil, true)
    end) 

end

function CharacterClass:StopTrack(Category)
    Category = Category or 'Default'
    -- print('Stopping track',Category, '\n', debug.traceback())
    if self.PlayingTracks[Category] then
        self.PlayingTracks[Category]:Stop()
        self.PlayingTracks[Category] = nil
    end
end

function CharacterClass:GetTrack(Track, TrackName)
    TrackName = TrackName or 'General'

    local Tracks = self.Tracks[TrackName]
    if Tracks and Tracks[Track] then
        
      

        return Tracks[Track]
    end
end

function CharacterClass:PlayTrack(Track, Category, Looped, TrackName)
    Category = Category or 'Default'
    TrackName = TrackName or 'General'

    self:StopTrack(Category)
    
    local _track = self:GetTrack(Track, TrackName)

    if _track then
        _track:Play()
        if Looped then
            _track.Looped = true
        end
        self.PlayingTracks[Category] = _track  

        return _track
    end
end

function CharacterClass:PlayWeaponTrack(Track, Category, Looped)
    return self:PlayTrack(Track, Category, Looped,self.WeaponSubtype)
end


function CharacterClass:CancelAction(_state)
    
    warn(_state, '===', self.State, self.StatePromise)
    if self.StatePromise then
        if _state and self.State ~= _state then return end

        self.StatePromise:cancel()
    end
end

function CharacterClass:EndSimultaneousRequests()
    self.Request = 1
end

function CharacterClass:CooldownState(t,state)
    self.CD[state or self.State] = os.clock() + t
end

function CharacterClass:GetMoveVector(): Vector3
    return self.ControlModule:GetMoveVector()
end

function CharacterClass:AddVelocity(velocity, duration)
    local mover = Util.new('LinearVelocity', {
        Parent = self.Character,
        VelocityConstraintMode = Enum.VelocityConstraintMode.Vector,
        RelativeTo = Enum.ActuatorRelativeTo.World,
        Attachment0 = self:GetRootAttachment(),
        MaxForce = 100000,
        VectorVelocity = velocity or Vector3.zero
    })
    if duration then
        Debris:AddItem(mover, duration)
    end
    return mover
end

function CharacterClass:AlignOrientation(CF, duration):AlignOrientation
    local mover = Util.new('AlignOrientation', {
        --RigidityEnabled = true,
        Responsiveness = 200,
        MaxTorque = 100000,
        Attachment0 = self:GetRootAttachment(),
        CFrame = CF or CFrame.new(),
        Parent = self.Root,
        Mode = Enum.OrientationAlignmentMode.OneAttachment
    })
    if duration then
        Debris:AddItem(mover, duration)
    end
    return mover
end

function CharacterClass:GetRootAttachment()
    return self.Root:FindFirstChild('RootAttachment') or Util.new('Attachment', {
        Parent = self.Root,
        Name = 'RootAttachment'
    })
end

function CharacterClass:ChangeState(newState, index)


    index = index or 1
    local State = States[newState]

    warn(self.State, self.StatePromise, newState)
    if self.CD[newState] and os.clock() < self.CD[newState] then
        return
    end


    if newState ~= self.State then
        if self.ChainedPromise then
            self.ChainedPromise:cancel()
        end
        self.Request = 1
    elseif State then
        if self.Request < (State.AcceptedRequestAmount or 1) then
            self.Request += 1
        end
      --  print('Attempted to trigger same state simultaneously, requests:',self.Request)
        return
    end

    warn('Proceeding new state')

    local NewStateApplied = false
    if self.State and self.StatePromise then
        self:SetAwaitingState(newState, index)
        self.StatePromise:cancel()
        self:SetAwaitingState()
        NewStateApplied = true
    end
    if not NewStateApplied then
        self:SetState(newState, index)    
    end
    --self.LastStateExecutions[Keybind] = os.clock()

    if State then
        
        local Request = 0

        local function trigger()
            local _promise
            if State.Trigger then
                _promise = self.Cleaner:AddPromise(State.Trigger(self))
            else
                _promise = self.Cleaner:AddPromise(Promise.new(function(resolve)
                    task.wait(State.Length or 1)
                    resolve()
                end))
            end
            _promise:finally(function()
                -- print('Disposing State Promise')
            
                self.LastStateExecutions[newState] = os.clock()
        
                -- if _promise == self.StatePromise then
                --     self.StatePromise = nil
                -- end
                
            end)
            -- self.StatePromise = _promise

            return _promise
        end

        local current = nil
        local t
        local chained;chained = Promise.new(function(resolve)
            
            if State.BeforeTrigger then
                t = State.BeforeTrigger(self)
            end
            while self.State == newState and Request < self.Request do
              --  print(`Triggered state {newState} for the {Request+1} time`,self.State, newState, Request, self.Request)
                current = trigger()
                current:await()
              --  print(`done {newState} {Request+1}`,self.State, newState, Request, self.Request)
                Request += 1
            end
            resolve()
        end):finally(function()
            if State.AfterTrigger then
                State.AfterTrigger(self, t)    
            end
            if current then
                current:cancel()    
            end
            if self.State == newState then
                local awaitingStates = self.AwaitingStates
                self:SetState(awaitingStates.State, awaitingStates.StateIndex)
            end
            if self.StatePromise == chained then
                self.StatePromise = nil
            end
        end)

        self.StatePromise = chained

    end

end

function CharacterClass:SetupStates()
    
    local InputController = Knit.GetController("InputController")

    for _, info in States do
        if info.Init then
            info.Init(self)
        end
    end

    self.Cleaner:Connect(InputController.KeybindTriggered, function(Keybind, index)
        local State = States[Keybind]
        
        print(self.State)

        if 
            not State or 
            (self.State and States[self.State].Disturbable==false) or 
            --(os.clock() - (self.LastStateExecutions[Keybind] or 0)) < (State.DelayAfter or 0) or
            (Keybind ~= self.State) and os.clock()<(self.StateExecutionCooldown or 0) or
            (State.Condition and not State.Condition(self))
        then
            return
        end
        self.StateExecutionCooldown = os.clock() + (State.DelayAfter or 0)


        self:ChangeState(Keybind, index)
    end)

    self.Cleaner:Connect(InputController.KeybindTriggerEnded, function(Keybind, index)
        local State = States[Keybind]

        if not State or self.State ~= Keybind or self.StateIndex ~= index then
            return
        end

        if self.StatePromise and State.Type == 'Hold' then
            self.StatePromise:cancel()
        end
    end)

    self.Cleaner:Connect(self.Humanoid.StateChanged, function(humstate)
        if humstate == Enum.HumanoidStateType.Jumping then
            if self.State and States[self.State].CancelOnJump then
                self:CancelAction()
            end    
        end
        
    end)

    return self
end

function CharacterClass:IsActive()
    return self.Active
end

function CharacterClass:AddStamina(amount, regen)
    self.Stamina = math.max(self.Stamina + amount, 0)
    self.StaminaChanged:Fire(self.Stamina, self.MaxStamina)

    if regen then return end
    
    self:StartStaminaRegen()

end

function CharacterClass:StartStaminaRegen()
    if self._stamina_regen then
        self._stamina_regen:cancel()
    end

    local done = false
    self._stamina_regen = Promise.delay(2):andThen(function()
        while not done and self.Stamina < self.MaxStamina do
            self:AddStamina(self.MaxStamina/100, true)
            task.wait(.1)
        end
    end):finally(function()
        done = true
        self._stamina_regen = nil
    end)
end

function CharacterClass:StartStaminaRegen_old()
    self._stamina_change_id = (self._stamina_change_id or 0)+ 1
    local this_id = self._stamina_change_id

    task.delay(2, function()
        if self._stamina_change_id == this_id then
            while (self._stamina_change_id == this_id) and self.Stamina < self.MaxStamina do
                self:AddStamina(self.MaxStamina/100, true)
                task.wait(.1)
            end
        end    
    end)
end

function CharacterClass:Raycast(direction, offset): RaycastResult
    local position = self.Root.Position + (offset or Vector3.zero)
    return workspace:Raycast(position, direction, self.RaycastParams), position
end

function CharacterClass:LookVector()
    return self.Root.CFrame.LookVector
end

function CharacterClass:RightVector()
    return self.Root.CFrame.RightVector
end

function CharacterClass:UpVector()
    return self.Root.CFrame.UpVector
end

function CharacterClass:AlignPosition(position: Vector3, duration: number): AlignPosition
    local mover: AlignPosition = Util.new('AlignPosition', {
        Attachment0 = self:GetRootAttachment(),
        Responsiveness = 200,
        Position = position,
        Mode = Enum.PositionAlignmentMode.OneAttachment,
        Parent = self.Root
    })
    if duration then
        Debris:AddItem(mover,duration)
    end
    return mover
end

function CharacterClass:Jump()
    self.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
end

function CharacterClass:CameraLookVector()
    return workspace.CurrentCamera.CFrame.LookVector
end

function CharacterClass:AdvancedRaycast(direction, length, offset, displacement)
    displacement = displacement or 1
    length = length or 1
    for i = 0, length, displacement do
        local result = self:Raycast(direction*i, offset)
        if result then
            return result
        end
    end
end

function CharacterClass:InitiateClimbing()
    local Cleaner: Trove.Trove = self.Cleaner
    local Humanoid: Humanoid = self.Humanoid
    local PriorityHumanoid = Priority:GetHandler(Humanoid)

    local ClimbDetector = Cleaner:Extend()
    local ActiveClimb = Cleaner:Extend()
    
    local CleanupClimbDetector = ClimbDetector:WrapClean()
    local CleanupActiveClimb = ActiveClimb:WrapClean()

    local LastClimb = 0 
    
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing,false)

    local CollisionParts = {
        --self.Root, 
        self.Character.Head, 
        self.Character.UpperTorso,
        self.Character.LowerTorso
    }

    local function SetCanCollide(enabled)
        for _, v in CollisionParts do
            v.CanCollide = enabled
        end
    end

    local function getDirection(moveVector)
        if moveVector.Z > 0 then
            return 1 -- Forward
        elseif moveVector.Z < 0 then
            return -1 -- Backward
        elseif moveVector.X > 0 then
            return 1 -- Right
        elseif moveVector.X < 0 then
            return 1 -- Left
        else
            return 0 -- No movement
        end
    end

    local function GetCameraLookVector()
        local Camera = workspace.CurrentCamera
        local CF = Camera.CFrame
        local LookVector = -CF.RightVector:Cross(Vector3.new(0,1,0))

        return LookVector
    end

    local function DetectWall(offset: Vector3)
        offset = offset or Vector3.zero

        local LookVector = GetCameraLookVector()
        --return self:AdvancedRaycast(LookVector, 4, offset + Vector3.new(0, -0.5, 0) - LookVector * 1), LookVector
        return self:Raycast(LookVector * 3, Vector3.new(0,-0.5,0) - LookVector * 1), LookVector
    end

    local function StartClimbing(Initial: RaycastResult)

        CleanupActiveClimb()

        local Anim: AnimationTrack = self:GetTrack('Climb')
        local Position = self:AlignPosition(Initial.Position + Initial.Normal*1)
        local Orientation = self:AlignOrientation()

        local initialVelocity = self.Root.AssemblyLinearVelocity.Magnitude
        local initialCf:CFrame = CFrame.lookAlong(Initial.Position, -Initial.Normal)
        local ws = Humanoid.WalkSpeed

        local climb_spring = spring.new(Position.Position)
        climb_spring.Speed = ws
        climb_spring:Impulse(initialCf.UpVector * initialVelocity + initialCf.RightVector * initialVelocity)

        Orientation.Responsiveness = 30
        Position.Responsiveness = 20

        local NoCollision: NoCollisionConstraint = Instance.new('NoCollisionConstraint')
        NoCollision.Parent = self.Root
        NoCollision.Part0 = self.Root

        --local AutoRotate = PriorityHumanoid:Add('AutoRotate', false, 1)
        local AutoRotate = self.Props.AutoRotate:Add(false)
        self.Climbing = true

        Anim:Play()
        Anim.Priority = Enum.AnimationPriority.Action4

        local LastClimb = os.clock()

        SetCanCollide(false)
        ActiveClimb:Add(Position)
        ActiveClimb:Add(Orientation)
        ActiveClimb:Add(NoCollision)
        ActiveClimb:Add(function()
            self.Climbing = false
        end)
        ActiveClimb:Add(function()
            Anim:Stop()
            SetCanCollide(true)
            AutoRotate:Dispose()
            Humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
        end)

        ActiveClimb:Connect(RunService.Heartbeat, function()

            local result, LookVector = DetectWall()

            local moveVector = self:GetMoveVector()
            if result then

                NoCollision.Part1 = result.Instance
                --local cameraCF =workspace.CurrentCamera.CFrame
             

                --print(x_climb.p, y_climb.p)
                local CF: CFrame = CFrame.lookAlong(result.Position, -result.Normal)

                local upVector = CF.UpVector
                local rightVector = CF.RightVector -- self:RightVector()

                
                local up = upVector * -moveVector.Z
                local right = rightVector * moveVector.X

                Anim:AdjustSpeed(getDirection(-moveVector))

                climb_spring.Target = (CF.Position + up + right)
                local ceil_result = self:Raycast(LookVector * -3 +  up * 3 + right * 3)

                if not ceil_result then    
                    Position.Position = climb_spring.p--(up * 0.3 + right * 0.2)
                    Orientation.CFrame = CF                    
                end

            else
                CleanupActiveClimb()
                self:Jump()
                print('done')
            end
        end)
    end

    local function StartClimbDetector()
        CleanupClimbDetector()
        ClimbDetector:Connect(RunService.Heartbeat, function()
            local result = DetectWall()
            if result and (os.clock() - LastClimb) > 0 then
                LastClimb = os.clock()
                StartClimbing(result)
                CleanupClimbDetector()
            end
        end)
    end

    Cleaner:Connect(Humanoid.StateChanged, function(old, new)
        if new == Enum.HumanoidStateType.Freefall then
            StartClimbDetector()
        elseif old == Enum.HumanoidStateType.Freefall then
            CleanupClimbDetector()
        end
    end)

    Cleaner:Connect(Humanoid:GetPropertyChangedSignal('Jump'), function()
        if Humanoid.Jump and self.Climbing then
           
            CleanupActiveClimb()

            local result, lookVector = DetectWall(Vector3.new(0, 2, 0))

            if result then
    
                local speed = 16
                if (os.clock() - LastClimb) < 0.2 then
                    speed = Humanoid.WalkSpeed
                end
               -- local align = self:AlignOrientation(cf, .3)
                local reflectionDirection = lookVector - 2 * (lookVector:Dot(result.Normal)) * result.Normal
                local cf: CFrame = CFrame.lookAlong(result.Position, reflectionDirection) * CFrame.Angles(math.rad(30),0,0)
                self:AddVelocity(cf.LookVector * 2 * speed, .08)
                Humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
                StartClimbDetector()
            else
                self:Jump()
            end

           
            
        end
    end)
end

function CharacterClass:AddCleanupTask(task)
    return self.Cleaner:Add(task)
end

function CharacterClass:InitiateClimbingMechanic()
    local ClimbDetectorTrove: Trove.Trove = self.Cleaner:Extend()
    local ActiveClimbTrove: Trove.Trove = self.Cleaner:Extend()
    local GlobalTrove: Trove.Trove = self.Cleaner
    local Humanoid: Humanoid = self.Humanoid
    
    local PriorityHumanoid = Priority:GetHandler(Humanoid)

    local CleanupClimbingDetector = ClimbDetectorTrove:WrapClean()
    local CleanupActiveClimbing = ActiveClimbTrove:WrapClean()

    local WallResult = nil
    local InitiateActiveClimbing, InitiateClimbingDetector

    local Cooldown = 0

    local Sleep = Promise.promisify(task.wait)
    local LastDebounce = 0
    local StopClimb = true

    local function CleanupAll()
        CleanupActiveClimbing()
        CleanupClimbingDetector()
    end

    local CollisionParts = {
        --self.Root, 
        self.Character.Head, 
        self.Character.UpperTorso,
        self.Character.LowerTorso
    }

    local function SetCooldown(s)
        Cooldown = os.clock() + s
    end

    local function SetCanCollide(enabled)
        for _, v in CollisionParts do
            v.CanCollide = enabled
        end
    end

    local function DetectWall()
        local root: BasePart = self.Root
        return workspace:Blockcast(root.CFrame, root.Size, root.CFrame.LookVector * 6, self.RaycastParams)
    end

    local function GetCameraLookVector()
        local CameraCF: CFrame = workspace.CurrentCamera.CFrame

        return -CameraCF.RightVector:Cross(Vector3.yAxis)
    end

    function InitiateActiveClimbing()
        CleanupAll()
        if not WallResult then return end
        Humanoid:ChangeState(Enum.HumanoidStateType.Climbing)

        self.Climbing = true
        print('Initiating Active Climbing')

        local function GetPosition()
            return WallResult.Position - self:LookVector() * 1
        end

        local function Wait(sec)
            return ActiveClimbTrove:AddPromise(Sleep(sec))
        end

        local function GetDirection(moveVector)
            if moveVector.Z > 0 then
                return 1 -- Forward
            elseif moveVector.Z < 0 then
                return -1 -- Backward
            elseif moveVector.X > 0 then
                return 1 -- Right
            elseif moveVector.X < 0 then
                return 1 -- Left
            else
                return 0 -- No movement
            end
        end

        local function Debounce(_stop)
            LastDebounce = os.clock()
            self.Root.CanCollide = false
        
            StopClimb = _stop == nil and true or false
        end

        local function testRay(origin, directions: {Vector3}, params)

            local index,dir = next(directions)
            
            while dir do
                local result = workspace:Raycast(origin, dir, params)
                if result then
                    return false, origin, result
                end
                origin = origin + dir
                index,dir = next(directions,index)
            end

            return true, origin
        end

        local transitions = nil
        local function transition(positions)
            transitions = positions
        end
    

        local function Jump()
            local lookVector = GetCameraLookVector()
            local reflectionDirection = lookVector - 2 * (lookVector:Dot(WallResult.Normal)) * WallResult.Normal
            local cf: CFrame = CFrame.lookAlong(WallResult.Position, reflectionDirection) * CFrame.Angles(math.rad(30),0,0)
            self:AddVelocity(cf.LookVector * 60, .08)
            Humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
        end

        local Position = self:AlignPosition(GetPosition())
        local Orientation = self:AlignOrientation(CFrame.lookAlong(WallResult.Position, -WallResult.Normal))
        local Anim: AnimationTrack = self:GetTrack('Climb')

        Position.Responsiveness = 45
        Orientation.Responsiveness = 30
        Orientation.RigidityEnabled = false

        SetCanCollide(false)
        --local AutoRotate = PriorityHumanoid:Add('AutoRotate', false, 1)
        local AutoRotate = self.Props.AutoRotate:Add(false)
        ActiveClimbTrove:Add(Orientation)
        ActiveClimbTrove:Add(AutoRotate,'Dispose')
        ActiveClimbTrove:Add(Position)
        ActiveClimbTrove:Add(function()
            SetCanCollide(true)
            Anim:Stop()
            self.Root.CanCollide = true
            self.Climbing = false
        end)

        Anim:Play()
        Anim.Priority = Enum.AnimationPriority.Action4
        

        Wait(0.1):andThen(function()
            ActiveClimbTrove:Connect(Humanoid:GetPropertyChangedSignal('Jump'), function()

                if Humanoid.Jump then

                    CleanupActiveClimbing()  
                    InitiateClimbingDetector() 
                    SetCooldown(.4)
                  
                end
                
                --InitiateClimbingDetector()
            end)
        end)

        ActiveClimbTrove:Connect(RunService.Heartbeat, function()

            if os.clock() - LastDebounce < 0.3 then
                self.Root.CanCollide = false
                if StopClimb == true then
                    return     
                end
            else
                StopClimb = false
                self.Root.CanCollide = true
            end

            local MoveVector = self:GetMoveVector()

            local lookVector: Vector3 = self:LookVector()
            local upVector: Vector3 = self:UpVector()


            WallResult = self:Raycast(lookVector*10)

            if WallResult then

                local wallLook = -(self:RightVector():Cross(Vector3.yAxis))
                
                if math.abs(wallLook:Dot(WallResult.Normal)) <= 0.5 then
                    return CleanupActiveClimbing()
                end

                local floorCeilResult = self:Raycast(upVector*-5*MoveVector.Z)

                if floorCeilResult and MoveVector.Z > 0 then

                    CleanupActiveClimbing()
                    
                    return
                elseif floorCeilResult then
                    local wideCheck = self:Raycast(upVector*5, -lookVector * 5)

                    if not wideCheck then
                        local origin = self.Root.Position - lookVector * 5 + upVector * 3
                        local newWallResult = workspace:Raycast(origin, lookVector * 5, self.RaycastParams)
                        if newWallResult then
                            WallResult = newWallResult
                            Debounce()
                        end
                    end
                elseif not floorCeilResult and MoveVector.Z > 0 then

                    local depthWall, origin = self:Raycast(lookVector*10, upVector*-3)

                    if depthWall and (depthWall.Position - origin).Magnitude > 2 then
                        WallResult = depthWall
                        Debounce()
                    end
                    
                end
                
                
            
                if WallResult then
                    
                    
                    local untransformedCF = CFrame.lookAlong(WallResult.Position, WallResult.Normal)

                    if math.abs(MoveVector.X) > 0 then
                        local rightVector = -untransformedCF.RightVector
                        local sideDirection = rightVector*6*MoveVector.X

                        local sideWallResult, origin = self:Raycast(sideDirection, -lookVector)
                        if sideWallResult then
                            WallResult = sideWallResult
                            Debounce()
                        else

                            local empty, newOrigin = testRay(origin, {
                                rightVector*MoveVector.X*0.2,
                                -untransformedCF.LookVector * 3
                            }, self.RaycastParams)

                            if empty then

                                local sideWallDirection = rightVector * 7 * -MoveVector.X
                                local othersideResult = workspace:Raycast(newOrigin, sideWallDirection, self.RaycastParams)
                                if othersideResult then
                                    Debounce()
                                    WallResult = othersideResult
                                end
                            end
                        end
                    end

                    local mantleResult = true
                    if MoveVector.Z < 0 then
                        mantleResult = self:Raycast(lookVector * 5, upVector * 4)
                    end
                    
                
                    
                    local CF = CFrame.lookAlong(WallResult.Position, WallResult.Normal)
                    local WS = Humanoid.WalkSpeed/16
                    Orientation.CFrame = CFrame.lookAlong(CF.Position, -WallResult.Normal)

                    local OldPosition = Position.Position

                    local NewPosition = (WallResult.Position + CF.LookVector) - CF.UpVector * MoveVector.Z * WS - CF.RightVector * MoveVector.X * WS * 0.8

                    if mantleResult then
                        Position.Position = NewPosition
                    else
                        
                        Debounce()
                        local surfaceResult = workspace:Raycast(NewPosition + CF.UpVector * 5 - CF.LookVector * 1, CF.UpVector * -10, self.RaycastParams)
                        Position.Position = surfaceResult and surfaceResult.Position + Vector3.yAxis * 3 or  NewPosition + CF.UpVector*4 - CF.LookVector*3
                        
                    end
                    

                    if (Position.Position - OldPosition).Magnitude > 0.02 then
                        Anim:AdjustSpeed(GetDirection(-MoveVector) * WS)
                    else
                        Anim:AdjustSpeed(0)
                    end
                    
                end
                
            else
                CleanupActiveClimbing()
                InitiateClimbingDetector() 
                SetCooldown(0.2)
            end
        end)

        Debounce(false)
    end

    function InitiateClimbingDetector()
        CleanupAll()

        local function Check()
            WallResult = self:Raycast(self:LookVector() * 5)
            if WallResult then
                InitiateActiveClimbing()
            end
        end

        ClimbDetectorTrove:Connect(RunService.Heartbeat, function()
            if os.clock() > Cooldown then
                Check()
            end
        end)

        ClimbDetectorTrove:AddPromise(Sleep(0)):andThen(function()
            ClimbDetectorTrove:Connect(Humanoid:GetPropertyChangedSignal('Jump'), function()
                if Humanoid.Jump then
                    Check()
                end
            end)
        end)
    end

    GlobalTrove:Connect(Humanoid.StateChanged, function(old: Enum.HumanoidStateType, new: Enum.HumanoidStateType)
        if new == Enum.HumanoidStateType.Freefall and not self.Climbing then
            InitiateClimbingDetector()
        elseif old == Enum.HumanoidStateType.Freefall then
            CleanupClimbingDetector()
        end
    end)
end

function Module:Initialize(CharModel: Model)
    local Cleaner = Trove.new()
    local SignalTrove = Trove.new()

    CombatService = Knit.GetService"CombatService"

    local InvController = Knit.GetController("InventoryController")
    local Stats = Knit.GetController('StatsClient')
    local Effect = Knit.GetController('EffectClient')

    local WeaponData = InvController:GetEquippedItem('Weapon')
    local WeaponInfo = Items[WeaponData]

    local Humanoid: Humanoid =  CharModel:WaitForChild('Humanoid')
    local PriorityHandler = Priority:GetHandler(Humanoid)

    PriorityHandler:SetDefaultValue('WalkSpeed', DEFAULT_WALKSPEED)
    PriorityHandler:SetDefaultValue('JumpPower', DEFAULT_JUMP_POWER)
    PriorityHandler:SetTweenInfo(TweenInfo.new(0.5,Enum.EasingStyle.Quart,Enum.EasingDirection.InOut)) 

    local camera = Priority:GetHandler(workspace.CurrentCamera)
    camera:SetTweenInfo(TweenInfo.new(0.4))
    camera:SetDefaultValue('FieldOfView', 70)

    local WalkSpeed = PriorityHandler:Add('WalkSpeed', DEFAULT_WALKSPEED * Stats:Get('MOVSPD'), 3)

    local params = RaycastParams.new()
    params.FilterDescendantsInstances = CharModel:GetChildren()


    local Character = setmetatable({
        Character = CharModel,
        Humanoid = Humanoid,
        Animator = Humanoid:WaitForChild"Animator",
        Root = CharModel:WaitForChild("HumanoidRootPart"),
        Active = true,
        Cleaner = Cleaner,
        State = nil,
        StateIndex = nil,
        StatePromise = nil,
        AwaitingStates = {
            State = nil,
            StateIndex = nil
        },
        Tracks = {},
        Weapon = {
            Data = WeaponData,
            Info = WeaponInfo,
            Id = WeaponData and WeaponData[3],
        },
        WeaponSubtype = nil,
        PlayingTracks = {},
        LastStateExecutions = {},
        UserData = {},
        Request  = 1,
        CD = {},
        ControlModule = ControlModule,
        PriorityHumanoid = PriorityHandler,
        WalkSpeed = WalkSpeed,

        Stamina = Stats:Get('Stamina'),
        MaxStamina = Stats:Get('Stamina'),

        StateChanged = SignalTrove:Construct(signal),
        StaminaChanged = SignalTrove:Construct(signal),

        RaycastParams = params,

        Props = Priority:GetHandler {
            AutoRotate = true;
        }

    }, CharacterClass)

    Cleaner:Add(function()
        Character.Active = false
        Character:SetState()

        if self.StatePromise then
            self.StatePromise:cancel()
        end
    end)

    Cleaner:Connect(Character.Humanoid.Died, function()
        Cleaner:Destroy()
        SignalTrove:Destroy()
    end)

    Cleaner:Connect(Stats:GetStatChanged('Stamina'), function(value)
        local scale = Character.Stamina/Character.MaxStamina
        Character.MaxStamina = value
        Character.Stamina = scale * value

        Character.StaminaChanged:Fire(Character.Stamina, Character.MaxStamina)
    end)

    Cleaner:Connect(Stats:GetStatChanged('MOVSPD'), function(value)
        WalkSpeed:Set(DEFAULT_WALKSPEED * value)
    end)

    Cleaner:Connect(Stats.LevelChanged, function(level, previous)
        if level > previous then
            Effect:SpawnEffect('LEVEL_UP', {
                Parent = Character.Root
            })
        end
    end)


    Character:SetupStates()
    Character:ResetWeaponAnimations()
    Character:SetupAnimations()
    Character:GetAnimationTracks('General', ReplicatedStorage.Assets.Animations)
    --Character:InitiateClimbing()
    Character:InitiateClimbingMechanic()
    print('Character Initialized')


    task.delay(0.03, Character.RefreshPlayingTracks, Character)

    return Character
end

export type Module = Module 

return Module