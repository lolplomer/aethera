local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Util = require(ReplicatedStorage.Utilities.Util)

local Effects = {}
local Module = {}

local Container = Util.new('Folder', {Name = 'EffectContainer', Parent = workspace})

local Knit = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Knit'))

function Module.LoadEffects(directory: Folder)
    for _, v in directory:GetChildren() do
        if v:IsA('BasePart') then
            Effects[v.Name] = {
                Object = v,
                Module = v:FindFirstChild('ModuleScript') and require(v.ModuleScript)
            }
            v.CanCollide = false
            v.Anchored = false
            v.CanQuery = false
            v.CanTouch = false
            v.Anchored = true
            v.Massless = true
        elseif v:IsA('ModuleScript') then
            Effects[v.Name] = {Module = require(v), IsModule = true}
        end
        
    end
end

function Module.SpawnEffect(effect, props)
    effect = Effects[effect]
    if effect then

        if effect.IsModule then
            return effect.Module.OnSpawn(props)
        end

        local object = effect.Object:Clone()

        if props.Parent then
            object.Anchored = false

            local weld = Util.new('Weld', {
                Parent = object,
                Part0 = props.Parent,
                Part1 = object,
                
            })

            if props.CFrame then
                weld.C0 = props.CFrame:ToObjectSpace(props.Parent.CFrame)
            end
            
            object.Parent = props.Parent
        else
            assert(props.CFrame, 'CFrame needs to be specified if without parent')

            object.CFrame = props.CFrame
            object.Parent = Container
        end

        local sounds =object:FindFirstChild('Sounds')
        if sounds then
            local SoundController = Knit.GetController('SoundController')
            for _, v in sounds:GetChildren() do
                local props = {
                    Parent = object, 
                    TimePosition = v.Value
                }
                for i,_v in v:GetAttributes() do
                    props[i] = _v
                end
                SoundController:PlaySound(v.Name, props)
            end
        end

        for _, v: Instance in object:GetDescendants() do
            if v:IsA('ParticleEmitter') then
                v:Emit(v:GetAttribute('Emit') or v:GetAttribute('EmitCount')  or props.Emit or 5)
            end
        end

        Debris:AddItem(object, props.Lifetime or 10)

        if effect.Module then
            props.TimePosition = props.TimePosition or os.clock()
            effect.Module.OnSpawn(object, props)
        end
    else
        warn('No such effect named',effect)
    end
end

Module.LoadEffects(ReplicatedStorage.Assets.VFX)

return Module 