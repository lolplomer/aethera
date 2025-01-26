local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local FrequencyTracker = {}
FrequencyTracker.__index = FrequencyTracker

local Trove = require(ReplicatedStorage.Packages.Trove)

function FrequencyTracker.new()
    local self = setmetatable({
        _callTracker = {};
        _trove = Trove.new();
        _watches = {},
    }, FrequencyTracker)
    return self
end

function FrequencyTracker:Destroy()
    self._trove:Destroy()
end

function FrequencyTracker:Tick()
    table.insert(self._callTracker, os.clock());
end

function FrequencyTracker:GetFrequency()
    local currentTime = os.clock()
    local startTime = currentTime - 1

    local CallTracker = self._callTracker

    for i = #CallTracker, 1, -1 do
        if CallTracker[i] < startTime then
            table.remove(CallTracker, i)
        end
    end

    return #CallTracker
end

function FrequencyTracker:Watch(fn)
    if not self._update then
        self._update = self._trove:Connect(RunService.Heartbeat, function()
            local freq = self:GetFrequency()
            for _, v in self._watches do
                v(freq);
            end
        end)
    end
    table.insert(self._watches, fn)
end

return FrequencyTracker
