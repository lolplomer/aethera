
local Default = {}

local Category = {}

local Type = {}

for _, v in script.Category:GetChildren() do
    if v:IsA('ModuleScript') then
        local Module = require(v)
        Module.Name = v.Name
        if not Module.Customization.List then
            Module.Customization.List = {}
        end
        Category[v.Name] = Module
        Default[v.Name] = Module.Customization.Default
    end
end

local cache = {}

return setmetatable({

    Default = Default,
    Category = Category,
    Type = Type

}, require(script.MainClass))