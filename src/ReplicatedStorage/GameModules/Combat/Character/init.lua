local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild"Packages"
local Trove = require(Packages:WaitForChild"Trove")
local BridgeNet2 = require(Packages:WaitForChild("bridgenet2"))

local Knit = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Knit'))

local GameModules = ReplicatedStorage:WaitForChild"GameModules"
local CombatFolder = GameModules:WaitForChild("Combat")
local States = require(CombatFolder:WaitForChild("States"))

local Util = require(ReplicatedStorage:WaitForChild("Utilities"):WaitForChild"Util")
local Priority = require(ReplicatedStorage.Utilities:WaitForChild"Priority")

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
    if Tracks and self.PlayingTracks[Category] == Tracks[Track] then
        return Tracks[Track] 
    end

    self:StopTrack()
    
    if Tracks and Tracks[Track] then
        Tracks[Track]:Play()
        self.PlayingTracks[Category] = Tracks[Track]

        if Looped then
            Tracks[Track].Looped = true
        end

        return Tracks[Track]
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

        local NewStateApplied = false

        if not State or self.State == Keybind then
            return
        elseif self.State and self.StatePromise then
            self:SetAwaitingState(Keybind, index)
            self.StatePromise:cancel()
            self:SetAwaitingState()
            NewStateApplied = true
        end

        if not NewStateApplied then
            self:SetState(Keybind, index)    
        end

        if State.Trigger then
            local _promise; _promise = self.Cleaner:AddPromise(State.Trigger(self))
            :finally(function()
               -- print('Disposing State Promise')
                if _promise == self.StatePromise then
                    self.StatePromise = nil
                end
                if self.State == Keybind then
                    local awaitingStates = self.AwaitingStates
                    self:SetState(awaitingStates.State, awaitingStates.StateIndex)
                end
            end)
            self.StatePromise = _promise
        end
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

    return self
end

function CharacterClass:IsActive()
    return self.Active
end



function Module:Initialize(CharModel: Model)
    local Cleaner = Trove.new()

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
        PlayingTracks = {}
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