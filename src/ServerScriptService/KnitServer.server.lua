local ReplicatedStorage = game:GetService"ReplicatedStorage"

local Knit = require(ReplicatedStorage.Packages.Knit)

Knit.AddServices(game.ServerStorage.Services)



do
    local Assets = {
        Assets = 16312860421, 
        Models = 13706951116
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
            Models.Name = "Models"
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

Knit.Start():andThen(function()
    warn("Knit Server has been started")
end):catch(warn)
