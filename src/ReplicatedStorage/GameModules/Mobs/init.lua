local module = {}

local mobs = {}

for _,v in script:GetChildren() do
    if v:IsA('ModuleScript') then
        local a = require(v)
        a.Name = v.Name
        
        mobs[v.Name] = a    
    end
end

module.Actions = {}

for _, v in script.Actions:GetChildren() do
    if v:IsA('ModuleScript') then
        local a = require(v)
        a.Name = v.Name

        module.Actions[v.Name] = a
    end
end

return setmetatable({}, {
    __index = function(_, index)
        return mobs[index] or module[index]
    end
})