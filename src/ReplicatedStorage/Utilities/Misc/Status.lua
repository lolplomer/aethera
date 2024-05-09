local Status = {}
Status.__index = Status

function Status.__tostring(self)
    return self.Success and "Success" or "Failed"
end

function Status.new(Success, Result)
    local self = setmetatable({
        Success = Success == true,
        Failed = Success ~= true,
    }, Status)

    if Result then
        for Key,Value in Result do
            self[Key] = Value
        end
    end

    return self
end

function Status:Set(Index, Value)
    self[Index] = Value or true
    return self
end

function Status.Success(Result)
    return Status.new(true, Result)
end

function Status.Failed(Result)
    return Status.new(false, Result)
end


return Status
