local util = {}

function util.GetEquipStatus(InvData, id)
    for type, equipData in InvData.Equipment do
        for pos_or_subtype, _id in equipData.Equips do
            if _id == id then
                return true, type, pos_or_subtype
            end
        end
    end
    return false
end

function util.GetEquippedType(InvData, Type, Subtype_or_Pos)
    local Id = InvData.Equipment[Type].Equips[Subtype_or_Pos]
    return InvData.Content[Id], Id
end

return util