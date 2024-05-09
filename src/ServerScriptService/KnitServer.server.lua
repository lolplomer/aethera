local ReplicatedStorage = game:GetService"ReplicatedStorage"

local Knit = require(ReplicatedStorage.Packages.Knit)

Knit.AddServices(game.ServerStorage.Services)


do
    local ModelsAssetId = 13706951116
    local InsertService = game:GetService("InsertService")

    local function UngroupModel(model, parent)
        for _, instance in model:GetChildren() do
            instance.Parent = parent or model.Parent
        end
        model:Destroy()
    end
    
    local Models = game.ReplicatedStorage:FindFirstChild("Models")
    if not Models then
        Models = Instance.new("Folder")
        Models.Name = "Models"
        Models.Parent = game.ReplicatedStorage
    end
    

    local success, errorMessage
    local package
    while not success do
        success, errorMessage = pcall(function()
            package = InsertService:LoadAsset(ModelsAssetId)
        end)
        if not success then
            warn("Failed to load Models:",errorMessage)
            task.wait(2)
        end
    end
    if package then
        print("Successfully updated Models")
        Models:ClearAllChildren()
        UngroupModel(package.Models, Models)
        package:Destroy()
    end
end


Knit.Start():andThen(function()
    warn("Knit Server has been started")
end):catch(warn)
