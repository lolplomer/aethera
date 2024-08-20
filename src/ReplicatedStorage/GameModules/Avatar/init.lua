
local Default = {}

local Category = {}

local Type = {}

for _, v in script.Category:GetChildren() do
    if v:IsA('ModuleScript') then
        local Module = require(v)
        Module.Name = v.Name
        Category[v.Name] = Module
        Default[v.Name] = Module.Default
    end
end



return table.freeze({
    Default = Default,
    Category = Category,
    Type = Type
})