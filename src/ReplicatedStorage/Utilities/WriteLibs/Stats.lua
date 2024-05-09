local WriteLib = {
    SetModifier = function(replica, id, modifier)
        replica:SetValue({"Modifiers",id}, modifier)
    end,
    SetModifiers = function(replica, modifiers)
        replica:SetValues({"Modifiers"}, modifiers)
    end,
    RemoveModifier = function(replica, id)
        replica:SetValue({'Modifiers',id}, nil)
    end,
    SetStats = function(replica, Level, BaseStats, FullStats)
        replica:SetValues({}, {
            BaseStats = BaseStats,
            Level = Level,
        })
        replica:SetValues({'FullStats'}, FullStats)
    end
}

return WriteLib