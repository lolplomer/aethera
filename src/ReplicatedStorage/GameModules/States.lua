local States = {

    MP = 0,
    Action = nil,

}

local __set = {
    MP = function(Value, Player, Stats, States)
        return math.min(Value, Stats.FullStats.MP)
    end
}

return {
    States = States,
    __set = __set
}