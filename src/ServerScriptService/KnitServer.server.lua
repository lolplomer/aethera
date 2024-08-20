local ReplicatedStorage = game:GetService"ReplicatedStorage"
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

require(ReplicatedStorage.Packages.bridgenet2)

game.Players.CharacterAutoLoads = false

local ClonePlayerModule = ReplicatedStorage.Assets.PlayerModule
local PlayerModule = game.StarterPlayer.StarterPlayerScripts:WaitForChild('PlayerModule')

local function fetch(names)
    local services = {}
    for _, v in names do
        services[v] = ServerStorage:FindFirstChild(v)
    end
    return services
end

for _, v in ClonePlayerModule:GetChildren() do
    local new = v:Clone()
    local old = PlayerModule:FindFirstChild(v.Name)
    if old then
        old:Destroy()
    end
    new.Parent = PlayerModule
end

if RunService:IsStudio() then
    do
        local Assets = {
            Assets = 16312860421, 
            Models = 13706951116,
            Items = 18159715585
        }
        local InsertService = game:GetService("InsertService")
    
        local function UngroupModel(model, parent)
            for _, instance in model:GetChildren() do
                instance.Parent = parent or model.Parent
            end
            model:Destroy()
        end
    
        for name, id in Assets do
            --print ('Loading asset ' .. id .. '...')
    
            local Models = game.ReplicatedStorage:FindFirstChild(name)
            if not Models then
                Models = Instance.new("Folder")
                Models.Name = name
                Models.Parent = game.ReplicatedStorage
            end
    
            local success, errorMessage
            local package
            while not success do
                success, errorMessage = pcall(function()
                    package = InsertService:LoadAsset(id)
                end)
                if not success then
                    warn("Failed to load Models:",errorMessage)
                    task.wait(2)
                end
            end
            if package then
                print('Successfully updated', name)
                Models:ClearAllChildren()
                UngroupModel(package[name], Models)
                package:Destroy()
            end
        end
    end
end


local services = fetch {'Services', 'PlaceServices'}

for _,v in services do
    Knit.AddServices(v)
end

Knit.Start():andThen(function()
    warn("Knit Server has been started")

    local KnitStarted = Instance.new('BoolValue')
    KnitStarted.Name = 'KnitServerStarted'
    KnitStarted.Value = true
    KnitStarted.Parent = ReplicatedStorage

end):catch(warn)
