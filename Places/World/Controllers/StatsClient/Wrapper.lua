local Wrapper = {}
Wrapper.__index = Wrapper

local Packages = game.ReplicatedStorage.Packages
local Trove = require(Packages.Trove)
local Signal = require(Packages.Signal)

function Wrapper.new(stats)
    local self = setmetatable({
        _stats = stats,
        _trove = Trove.new(),
        _changed = {},
    }, Wrapper)

    stats.Replica:AddCleanupTask(function()
        self:Destroy()
    end)

    for name in stats.FullStats do
        local connection = stats.Replica:ListenToChange({'FullStats',name}, function(value, old)
            --print(name, 'changed', value)
            self:GetStatChanged(name):Fire(value, old)
        end)
        self._trove:Add(connection)
    end

    self.LevelChanged = self._trove:Construct(Signal)

    self._trove:Add(stats.Replica:ListenToChange('Level', function(value)
        self.LevelChanged:Fire(value)
    end))

    return self
end

function Wrapper:Get(stat)
    return self._stats.FullStats[stat]
end

function Wrapper:GetStatChanged(stat)
    if not self._changed[stat] then
        self._changed[stat] = self._trove:Construct(Signal)
    end
    return self._changed[stat]
end

function Wrapper:GetLevel()
    return self._stats.Level
end

function Wrapper:Destroy()
   self._trove:Destroy() 
end


return Wrapper
