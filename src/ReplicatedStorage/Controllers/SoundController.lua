local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local SoundController = Knit.CreateController { Name = "SoundController" }

local Assets = game.ReplicatedStorage.Assets
local SoundFolder = Assets.Sounds

local Sounds = {}
local Groups = {}

function SoundController:InitiateSounds()
    for _, folder in SoundFolder:GetChildren() do
        local Group = Instance.new('SoundGroup')
        Group.Name = folder.Name
        Group.Parent = SoundService

        for _, sound: Sound in folder:GetChildren() do
            
            sound.RollOffMaxDistance = 200
            sound.RollOffMinDistance = 200
            sound.RollOffMode = Enum.RollOffMode.LinearSquare

            Sounds[sound.Name] = sound
            Groups[sound] = Group
        end
    end
end

function SoundController:PlaySound(name, props)
    props = props or {}
    local sound = Sounds[name]
    local soundGroup = Groups[sound]
    if sound and soundGroup then
        sound = sound:Clone()
        

        sound.Volume *= soundGroup.Volume

        sound.Parent = props.Parent or SoundService
        if props.TimePosition then
            sound.TimePosition = props.TimePosition
        end
        
        task.delay(0, function()
            if not sound.IsLoaded then
                sound.Loaded:Wait()
            end

            local Volume = sound.Volume

            
            if props.FadeIn then
               sound.Volume = 0
               TweenService:Create(sound, TweenInfo.new(props.FadeIn, Enum.EasingStyle.Linear), {Volume = Volume}) :Play()
            end

            sound:Play()

            local End = props.End or sound.TimeLength
            
            if props.FadeIn then
                task.delay(End-props.FadeIn, function()
                    TweenService:Create(sound, TweenInfo.new(props.FadeOut, Enum.EasingStyle.Linear),{
                        Volume = 0
                    }):Play()
                end)
            end


            Debris:AddItem(sound, End)    
        end)
        



    end
end

function SoundController:KnitInit()
    self:InitiateSounds()
end


return SoundController
