local module = {}

for _,v in script:GetChildren() do
    module[v.Name] = require(v)
end

return module