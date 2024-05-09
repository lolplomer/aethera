local iconManager = {}

local iconModule = require(game.ReplicatedStorage:WaitForChild"Utilities":WaitForChild"Icon")

local iconController = require(game.ReplicatedStorage.Utilities.Icon:WaitForChild"IconController")
iconController.voiceChatEnabled = true
iconController:setLeftOffset(10)

local icons = {}

function  newIcon(iconName)
   if icons[iconName] then
    return icons[iconName]
   end

    icons[iconName] = iconModule.new()

    return icons[iconName]
end

iconManager.Controller = iconController

setmetatable(iconManager, {
    __call = function(_, iconName)
        return newIcon(iconName)
    end
})

return iconManager