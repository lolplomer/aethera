local ColorUtil = {}

function ColorUtil.Multiply(color, mul, type)
    local h,s,v = color:ToHSV()
    if type == "H" then
        return Color3.fromHSV(h*mul,s,v)
    elseif type == "S" then
        return Color3.fromHSV(h,s*mul,v)
    elseif type == "V" then
        return Color3.fromHSV(h,s,v*mul)
    end 
    return Color3.fromHSV(h*mul,v*mul,s*mul)   
end

function ColorUtil.MultiplyValue(color, mul)
    return ColorUtil.Multiply(color, mul, "V")
end

function ColorUtil.MultiplySaturation(color, mul)
    return ColorUtil.Multiply(color, mul, "S")
end

function ColorUtil.MultiplyHue(color, mul)
    return ColorUtil.Multiply(color, mul, "H")
end

return ColorUtil