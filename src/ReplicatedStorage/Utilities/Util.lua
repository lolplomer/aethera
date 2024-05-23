local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Util = {}

local Assets = ReplicatedStorage:WaitForChild'Assets'

function Util.GetAsync(Source, Index, Name)

    local Time = os.clock() + 5
    local Warned = false

    while not Source[Index] do
        task.wait()
        if os.clock() > Time and not Warned then
            Warned = true
            warn(`Infinite yield possible on getting {Index} :: {Name}`)
        end
    end

    return Source[Index]    
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

function Util.CharacterAdded(player, Function)
    local function OnCharacterAdded(character)
        Util.WaitUntilParentIsWorkspace(character)
        Function(character)
    end
    OnCharacterAdded(player.Character or player.CharacterAdded:Wait())
    return player.CharacterAdded:Connect(OnCharacterAdded)
end

function Util.ReadItemStats(itemStats, lvl)
    
    local StatFormula = require(script.Parent.Misc.StatFormula)
    local StatModule = require(game.ReplicatedStorage.GameModules.Stats)

    lvl = lvl or 1

    local Stats = {}
    for stat, itemStat in itemStats do
        local Mult = StatModule[stat].LevelMultiplier
        local Value = StatFormula.GetBaseStat(lvl, itemStat[1], Mult)
        if itemStat[2] then
            Stats[stat] = {
                Flat = 0,
                Multiplier = Value
            }
        else
            Stats[stat] = {
                Flat = Value,
                Multiplier = 0
            }
        end
    end
    return Stats
end

return Util