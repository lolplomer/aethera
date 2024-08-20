local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Util = {}

local Assets = ReplicatedStorage:WaitForChild'Assets'

function Util.GetAsync(Source, Index, Name, Timeout)

    local Time = os.clock() + (Timeout or 5)
    local Warned = false

    while not Source[Index] do
        task.wait()
        if os.clock() > Time and not Warned then
            Warned = true
            if Timeout then
                return
            end
            warn(`Infinite yield possible on getting {Index} :: {Name}`)
            
        end
    end

    return Source[Index]    
end

function Util.MakeSolid(model: Model)
    for _,v: BasePart in model:GetDescendants() do
        
        if v:IsA('BasePart') then
        
           v.CanCollide = true
           v.Anchored = false 
           v.Massless = false
           v.CustomPhysicalProperties = PhysicalProperties.new(Enum.Material.Metal)
        end
    end 
end

function Util.PrimaryPart(model: Model)
    return model.PrimaryPart or model:FindFirstChildOfClass('BasePart')
end

function Util.RollChances(weightsTable)
    local totalWeight = 0
    for _, weight in pairs(weightsTable) do
        totalWeight = totalWeight + weight
    end

    local randomValue = math.random() * totalWeight
    local cumulativeWeight = 0

    for outcome, weight in pairs(weightsTable) do
        cumulativeWeight = cumulativeWeight + weight
        if randomValue < cumulativeWeight then
            return outcome
        end
    end
end

function Util.WaitUntilParentIsWorkspace(model: Instance)
    while model.Parent ~= workspace do
        model.AncestryChanged:Wait()
    end
end

function Util.GetWeaponFolder(Subtype)
    return Assets:WaitForChild'Weapons'[Subtype]
end

function Util.ComparePath(path1, path2)
    for i,v in path2 do
        if path1[i]~=v then
            return false
        end
    end
    return true
end

local Debounces = {}
function Util.Debounce(Name,t)
    if os.clock()-(Debounces[Name] or 0)>t then
        Debounces[Name] = os.clock()
        return true
    end
    return false
end

function Util.GetAnimationFolder(WeaponFolder: Folder, Animation)
    return WeaponFolder.Animations:FindFirstChild(Animation)
end

function Util.CharacterAdded(player, Function, yield)
    local function OnCharacterAdded(character)
        Util.WaitUntilParentIsWorkspace(character)
        Function(character)
    end
    
    if yield ~= false then
        OnCharacterAdded(player.Character or player.CharacterAdded:Wait())
    elseif player.Character then
        OnCharacterAdded(player.Character)
    end
    
    return player.CharacterAdded:Connect(OnCharacterAdded)
end

function Util.new(name, props, children)
    local instance = Instance.new(name)
    for prop, value in props do
        instance[prop] = value
    end
    if children then
        for i,v in children do
            v.Parent = instance
            v.Name = i
        end
    end
    return instance
end

function Util.ReadItemStats(itemStats, lvl)
    
    local StatFormula = require(script.Parent.Misc.StatFormula)
    local StatModule = require(game.ReplicatedStorage.GameModules.Stats)

    lvl = lvl or 1

    local Stats = {}
    for stat, itemStat in itemStats do
        local metadata = StatModule[stat]
        local Mult = itemStat[3] or metadata.LevelMultiplier
        local Value = StatFormula.GetBaseStat(lvl, itemStat[1], Mult)
        
        if metadata.IsPercentage or not itemStat[2] then
            Stats[stat] = {
                Flat = Value,
                Multiplier = 0
            }
        else
            Stats[stat] = {
                Flat = 0,
                Multiplier = Value
            }
        end
    end
    return Stats
end

function Util.command(name, fn)
    local TextChatService = game:GetService('TextChatService')
    local command = Util.new('TextChatCommand', {
        Parent = TextChatService:WaitForChild('TextChatCommands'),
        PrimaryAlias = `/{name:lower()}`
    })
    command.Triggered:Connect(function(source: TextSource, text: string)
        local args = text:split(' ')
        table.remove(args, 1)
        fn(game.Players:GetPlayerByUserId(source.UserId), args)
    end)
end

function Util.Highlight(text, color)
    color = color or Color3.new(1,1,1)
    return `<font color="#{color:ToHex():upper()}">{text}</font>`
end

function Util.SecondsToFormattedTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60

    if hours > 0 then
        return string.format("%02d:%02d:%02d", hours, minutes, secs)
    else
        return string.format("%02d:%02d", minutes, secs)
    end
end

function Util.GetLongestActiveDuration(t)
    local selectedKey, selectedTimeStart, selectedTimeEnd = nil, nil, nil
    local maxRemainingDuration = -math.huge
    local currentTime = os.clock()
    
    for key, data in pairs(t) do
        if data.TimeEnd < 0 then
            selectedKey, selectedTimeStart, selectedTimeEnd = key, data.TimeStart, data.TimeEnd
            break
        else
            local remainingDuration = data.TimeEnd - currentTime
            if remainingDuration > 0 and remainingDuration > maxRemainingDuration then
                selectedKey, selectedTimeStart, selectedTimeEnd = key, data.TimeStart, data.TimeEnd
                maxRemainingDuration = remainingDuration
            end
        end
    end

    return selectedKey, selectedTimeStart, selectedTimeEnd
end


function Util.CardinalConvert(dir)
	local angle = math.atan2(dir.X, -dir.Z)
	local quarterTurn = math.pi / 2
	angle = -math.round(angle / quarterTurn) * quarterTurn
	
	local newX = -math.sin(angle)
	local newZ = -math.cos(angle)
	if math.abs(newX) <= 1e-10 then newX = 0 end
	if math.abs(newZ) <= 1e-10 then newZ = 0 end
	return Vector3.new(newX, 0, newZ)
end

local rad = math.rad
local Angles = {
    [Vector3.new(0, 0, -1)] = CFrame.Angles(0, 0, 0),
    [Vector3.new(0, 0, 1)] = CFrame.Angles(0, rad(180), 0),
    [Vector3.new(1, 0, 0)] = CFrame.Angles(0, rad(90), 0),
    [Vector3.new(-1, 0, 0)] = CFrame.Angles(0, rad(-90), 0),
}
function Util.MoveVectorToAngle(moveVector)
    return Angles[moveVector] or CFrame.Angles()
end

return Util