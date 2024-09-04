local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local Promise = require(ReplicatedStorage.Utilities.Promise)
local Util = require(ReplicatedStorage.Utilities.Util)
local Signal = require(ReplicatedStorage.Packages.Signal)

local AvatarModule = require(ReplicatedStorage.GameModules.Avatar)

local AvatarController = Knit.CreateController { Name = "AvatarController" }
AvatarController.Editor = {}
AvatarController.EditorChanged = Signal.new()

local Rigs = {}

local DataEdit = {}
local AvatarData = nil

local GetService = Util.GetService
local GetController = Util.GetController

local PlayerDataController

function AvatarController:KnitStart()
    PlayerDataController = GetController('PlayerDataController'):expect()

    AvatarData = Promise.new(function(resolve,reject)
        if PlayerDataController then
            local PlayerData = PlayerDataController:GetDataAsync():timeout(5):expect()

            resolve(PlayerData and PlayerData.Avatar)
        else
            warn(`Missing PlayerDataController to fetch Avatar Data`)
        end
        reject()
    end)
end

function AvatarController:GetAvatarData()
    return AvatarData
end

function AvatarController:HasCustomizedAvatar()
    return AvatarData:expect().Customized
end

function AvatarController:StartEditingAvatar()
    return AvatarData:andThen(function(data)
        if data then
            DataEdit = table.clone(data.Data)
            self:UpdatePreview()
        else
            warn('Cannot start editing avatar: Player does not have AvatarData')
        end
    end)

end

function AvatarController:GetEditingData()
    return DataEdit
end

function AvatarController:SaveAvatarCustomizationAsync()
    return Promise.new(function(resolve,reject)
        local AvatarService = GetService('AvatarService'):expect()
        if AvatarService then
            resolve(AvatarService:SaveAvatar(DataEdit):expect())
        else
            reject('No AvatarService')
        end
    end)
    
    
end

function AvatarController:AddRigPreview(Rig: Model)
    table.insert(Rigs, Rig)
end

function AvatarController:UpdatePreview(category: string?, rig: Model?)
    if not rig then
        for _, _rig in Rigs do
            self:UpdatePreview(category, _rig)
        end
    else
        if not category then
            for _category in DataEdit do
                self:UpdatePreview(_category, rig)
            end
        else
            AvatarModule:ApplyCategory(category, rig, DataEdit[category])
        end
    end
end

function AvatarController:EditAvatar(Data: {})
    
    for category, newValue in Data do
        local Module = AvatarModule.Category[category]


        if Module and DataEdit[category] then
            DataEdit[category] = newValue

            self:UpdatePreview(category)

            if Module.Customization.ReapplyWhenChanged then
                for _, _category in Module.Customization.ReapplyWhenChanged do
                    print('Reupdating preview',_category)
                    self:UpdatePreview(_category)
                end
            end
            
            self.EditorChanged:Fire(category, newValue)
        else
            warn(`Unknown avatar category {category}`)
        end
    end
end

function AvatarController.Editor:AddSelectionIndex(category: string, index)
    local Module = AvatarModule.Category[category]
    local Value = tonumber(DataEdit[category])
    if Module.Customization.Type == 'Selection' and Value and #Module.Customization.List > 0 then
    
        local Max = #Module.Customization.List
        Value += index

        if Value > Max then
            Value = 1
        elseif Value < 1 then
            Value = Max
        end

        AvatarController:EditAvatar {
            [category] = Value
        }
    end
end

function AvatarController.Editor:NextSelection(category: string)
   self:AddSelectionIndex(category, 1) 
end

function AvatarController.Editor:PreviousSelection(category: string)
    self:AddSelectionIndex(category, -1) 
end

return AvatarController
