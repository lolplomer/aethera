

local function Attach(Part0, Part1)
    local Motor = Instance.new("Motor6D")
    Motor.Part0 = Part0
    Motor.Part1 = Part1
    Motor.Parent = Part0
    return Motor
end

local function OnDestroy(Instance: Instance, Fn)
    Instance.AncestryChanged:Connect(function(_, parent)
        if not parent then
            Fn()
        end
    end)
end

local function AttachWeaponModel(Model, Character)
    Model.Parent = Character
    local Motor = Attach(Character.RightHand, Model.PrimaryPart)
    Motor.Name = "WeaponHandle"
    OnDestroy(Model, function()
        Motor:Destroy()
    end)
end

local function AttachModel(Model, Character)
    Model.Parent = Character
end

local Type = {
    Weapon = {
        Subtype = {
            Sword = {},
            Bow = {},
            Longsword = {},
            Staff = {}, 
        },
        Method = "Single",
        MaxEquips = 2,
        ApplyInstance = function(Metadata, Model, Character, Player)
            AttachWeaponModel(Model, Character)
        end,
    },
    Body = {
        Subtype = {
            Torso = {Icon = "rbxassetid://15103095167"},
            Legs = {Icon = "rbxassetid://15115612317"}
        },
        Method = "Multiple",
        ApplyInstance = function(Metadata, Model, Character, Player)
            AttachModel(Model, Character)
        end
    },
}

local function Init()
    for _, Info in Type do
        Info.MaxEquips = Info.MaxEquips or 1
    end
end

Init()

return Type