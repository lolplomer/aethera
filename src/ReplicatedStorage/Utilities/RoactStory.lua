local ReplicatedStorage = game:GetService("ReplicatedStorage")
local roact = require(ReplicatedStorage.Utilities.Roact)

local reactRoblox = require(ReplicatedStorage.Packages["react-roblox"])

return function (component)
    
    return function (target)
       
        local root = reactRoblox.createRoot(target)

        root:render(roact.createElement(component))
        
        return function ()
            root:unmount() 
        end
    end

end