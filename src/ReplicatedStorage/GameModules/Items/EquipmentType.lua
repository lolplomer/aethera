

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

local function AttachModel(Model:Model, Character)
    if Model:IsA'Accessory' then
        Model.Parent = Character
    else
        local accessories = Model:GetChildren()
        for _,v in accessories do
            v.Parent = Character
        end
        Model.Parent = Character
        OnDestroy(Model, function()
            for _,v in accessories do
                v:Destroy()
            end
        end)
    end
    
end 

local function weldAttachments(attach1, attach2)
    local weld = Instance.new("Weld")
    weld.Part0 = attach1.Parent
    weld.Part1 = attach2.Parent
    weld.C0 = attach1.CFrame
    weld.C1 = attach2.CFrame
    weld.Parent = attach1.Parent
    return weld
end
 
local function buildWeld(weldName, parent, part0, part1, c0, c1)
    local weld = Instance.new("Weld")
    weld.Name = weldName
    weld.Part0 = part0
    weld.Part1 = part1
    weld.C0 = c0
    weld.C1 = c1
    weld.Parent = parent
    return weld
end
 
local function findFirstMatchingAttachment(model, name)
    for _, child in pairs(model:GetChildren()) do
        if child:IsA("Attachment") and child.Name == name then
            return child
        elseif not child:IsA("Accoutrement") and not child:IsA("Tool") then -- Don't look in hats or tools in the character
            local foundAttachment = findFirstMatchingAttachment(child, name)
            if foundAttachment then
                return foundAttachment
            end
        end
    end
end
 
local function addAccoutrement(character, accoutrement)  
    accoutrement.Parent = character
    local handle = accoutrement:FindFirstChild("Handle")
    if handle then
        local accoutrementAttachment = handle:FindFirstChildOfClass("Attachment")
        if accoutrementAttachment then
            local characterAttachment = findFirstMatchingAttachment(character, accoutrementAttachment.Name)
            if characterAttachment then
               -- print('Attachment',accoutrement,character,characterAttachment)
                handle.CFrame = characterAttachment.WorldCFrame * accoutrementAttachment.CFrame:inverse()
                --weldAttachments(characterAttachment, accoutrementAttachment)
            end
        else
            local head = character:FindFirstChild("Head")
            if head then
                local attachmentCFrame = CFrame.new(0, 0.5, 0)
                local hatCFrame = accoutrement.AttachmentPoint
                buildWeld("HeadWeld", head, head, handle, attachmentCFrame, hatCFrame)
            end
        end
    end
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
        LayoutOrder = 1,
    },
    Body = {
        Subtype = {
            Torso = {Icon = "rbxassetid://15103095167"},
            Legs = {Icon = "rbxassetid://15115612317"}
        },
        Method = "Multiple",
        ApplyInstance = function(Metadata, Model, Character, Player)
            AttachModel(Model, Character)
        end,
        ApplyInstanceViewport = function(Model, Character)
            for _,v in Model:GetChildren() do
                if v:IsA"Accessory" then
                    print('applying',v)
                    addAccoutrement(Character, v)
                end
            end
        end,
        LayoutOrder = 2,
    },
    Arcanites = {
        Subtype = {
            Necklace = {},
            Ring = {},
            Bracelet = {},
            Glove = {},
        },
        Method = "Multiple",
        ApplyInstance = function(Metadata, Model, Character, Player)
            AttachModel(Model, Character)
        end,
        ApplyInstanceViewport = function(Model, Character)
            for _,v in Model:GetChildren() do
                if v:IsA"Accessory" then
                    print('applying',v)
                    addAccoutrement(Character, v)
                end
            end
        end,
        LayoutOrder = 3,
    },
}

local function Init()
    for _, Info in Type do
        Info.MaxEquips = Info.MaxEquips or 1
    end
end

Init()

return Type