local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

local Module = {}

local CharacterClass = {}
CharacterClass.__index = CharacterClass

local StateChanged = BridgeNet2.ReferenceBridge("StateChanged")

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
    self:RefreshPlayingTracks()

    print('Resetted Weapon Animations')
    self.AnimTrove = AnimTrove

    for _,v in States do
        if v.WeaponAnimationReset then
            v.WeaponAnimationReset(self, self:GetWeaponTracks())
        end
    end

    if self.State and States[self.State].CancelOnWeaponChange then
        self:CancelAction()
    end

end

function CharacterClass:IsMoving()
    return self.Humanoid.MoveDirection.Magnitude > 0
end

function CharacterClass:RefreshPlayingTracks()
    self:PlayWeaponTrack(self:IsMoving() and 'Running' or 'Idle', nil, true)
end

function CharacterClass:SetupAnimations()
    local InvController = Knit.GetController('InventoryController')

    self.Cleaner:Add(
        InvController:ListenOnEquipmentSwitch('Weapon', function(item, position, itemInfo)
            print('Weapon Changed:', item, position, itemInfo)

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

    if self.PlayingTracks[Category] then
        self.PlayingTracks[Category]:Stop()
        self.PlayingTracks[Category] = nil
    end
end


function CharacterClass:PlayWeaponTrack(Track, Category, Looped)
    Category = Category or 'Default'

    local Tracks = self.Tracks[self.WeaponSubtype]
    -- if Tracks and Tracks[Track].IsPal then
    --     return Tracks[Track] 
    -- end

    self:StopTrack(Category)
    
    if Tracks and Tracks[Track] then
        Tracks[Track]:Play()
        self.PlayingTracks[Category] = Tracks[Track]

        if Looped then
            Tracks[Track].Looped = true
        end

        return Tracks[Track]
    end
end


function CharacterClass:CancelAction()
    if self.StatePromise then
        self.StatePromise:cancel()
    end
end

function CharacterClass:EndSimultaneousRequests()
    self.Request = 1
end

function CharacterClass:CooldownState(t,state)
    self.CD[state or self.State] = os.clock() + t
end

function CharacterClass:ChangeState(newState, index)


    index = index or 1
    local State = States[newState]

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



function Module:Initialize(CharModel: Model)
    local Cleaner = Trove.new()

    CombatService = Knit.GetService"CombatService"

    local InvController = Knit.GetController("InventoryController")

    local WeaponData = InvController:GetEquippedItem('Weapon')
    local WeaponInfo = Items[WeaponData]

    local Humanoid: Humanoid =  CharModel:WaitForChild('Humanoid')

    local conn = game:GetService("TextChatService").SendingMessage:Connect(function(message)
        local args = message.Text:split(" ")
        print(message.Text, args)
        if args[1] == 'setwalkspeed' then
            local value, prop = tonumber(args[2]), tonumber(args[3])
            print('setting walkspeed',value,prop)
            Priority.Set(Humanoid, 'WalkSpeed', value, prop)
        end
    end)
    print('chatted:',conn)

    local PriorityHandler = Priority:GetHandler(Humanoid)

    PriorityHandler:SetDefaultValue('WalkSpeed', 16)
    PriorityHandler:SetTweenInfo(TweenInfo.new(0.5,Enum.EasingStyle.Quart,Enum.EasingDirection.InOut)) 

    local camera = Priority:GetHandler(workspace.CurrentCamera)
    camera:SetTweenInfo(TweenInfo.new(0.4))
    camera:SetDefaultValue('FieldOfView', 70)

    local Character = setmetatable({
        Character = CharModel,
        Humanoid = Humanoid,
        Animator = Humanoid:WaitForChild"Animator",
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

        StateChanged = Cleaner:Construct(signal)
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
    end)

    Character:SetupStates()
    Character:ResetWeaponAnimations()
    Character:SetupAnimations()
    
    print('Character Initialized')

    return Character
end

return Module