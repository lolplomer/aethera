local Tagger = {}
Tagger.__index = Tagger

local DEFAULT_CUSTOM_DISTRIBUTION_CONDITION = function()
    return true
end

function Tagger.new(timeout)
    local self = setmetatable({
        _taggers = {},
        _distributeCondition = DEFAULT_CUSTOM_DISTRIBUTION_CONDITION,
        _timeout = timeout or 120,
        _last_tag = nil
    }, Tagger)
    return self
end

function Tagger.forInstance(timeout)
    local self = Tagger.new(timeout)

    self:SetCustomDistributeCondition(function(tagger: Instance)
        local player = game.Players:GetPlayerFromCharacter(tagger)
        return player and player:IsDescendantOf(game.Players)
    end)

    return self
end

function Tagger:Tag(tagger, point)
    if not self._taggers[tagger] then
        self._taggers[tagger] = {point = 0, last_tag = 0}
    end
    self._taggers[tagger].point += point
    self._taggers[tagger].last_tag = os.clock()

    self._last_tag = tagger

    if self.CombatData then
        self.CombatData.DamageTaken:Fire(tagger, point)
    end
end

function Tagger:GetLastTag()
    return self._last_tag
end

function Tagger:SetCustomDistributeCondition(fn)
    self._distributeCondition = fn
end

function Tagger:Reset()
    self._taggers = {}
end

function Tagger:Reconcile()

    for tagger, contribute in self._taggers do
        if self._distributeCondition(tagger, contribute) ~= true or os.clock() - contribute.last_tag > self._timeout then
            self._taggers[tagger] = nil
        end
    end
end

function Tagger:Distribute(callback)
    self:Reconcile()
    
    local total_points = 0
    for _, contribute in self._taggers do
        total_points += contribute.point
    end
    --print(total_points, self._taggers)
    if total_points > 0 then     
        for tagger, contribute in self._taggers do
            callback(tagger, contribute.point/total_points)
        end        
    end

end

function Tagger:SetCombatData(CombatData)
    self.CombatData = CombatData
end


return Tagger
