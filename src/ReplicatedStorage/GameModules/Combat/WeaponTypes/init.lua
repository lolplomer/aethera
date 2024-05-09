local WeaponTypes = {}

for _, v in script:GetChildren() do
    WeaponTypes[v.Name] = require(v)
end

return WeaponTypes