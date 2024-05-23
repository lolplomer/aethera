local None = 'None'

local loaded = {}

return setmetatable({}, {
    __index = function(_,index)
        local v = loaded[index]
        if not v then
            loaded[index] = script:FindFirstChild(index) and require(script[index]) or None
        end
        return v == None and nil or v
    end
})