return {
    SetPassive = function(replica, passiveName, level)
        replica:SetValue({"Passives",passiveName}, {Level = level})
    end,
    RemovePassive = function(replica, passiveName)
        replica:SetValue({"Passives",passiveName}, nil)
    end
}