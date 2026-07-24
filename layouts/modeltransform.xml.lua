require "globvars"

function on_open()
    document.slidemdlx.text = "" .. globvars.model.x
    document.slidemdly.text = "" .. globvars.model.y
    document.slidemdlz.text = "" .. globvars.model.z
    
    updmdlrx(globvars.model.rx)
    updmdlry(globvars.model.ry)
    updmdlrz(globvars.model.rz)

    document.slidemdlsx.text = "" .. globvars.model.sx
    document.slidemdlsy.text = "" .. globvars.model.sy
    document.slidemdlsz.text = "" .. globvars.model.sz

    -- =====================================================

    document.slidetexx.text = "" .. globvars.texture.x
    document.slidetexy.text = "" .. globvars.texture.y
    
    updtexrx(globvars.texture.rx)
    updtexry(globvars.texture.ry)

    document.slidetexsx.text = "" .. globvars.texture.sx
    document.slidetexsy.text = "" .. globvars.texture.sy
end

function round(num, digits)
    digits = math.floor(digits)
    if digits <= 0 then error("'digits' must be positive integer") end
    local exp = 10 ^ digits
    return math.round(num * exp) / exp
end

--[[
function centerpanel()
    return vec2.sub(vec2.mul(gui.get_viewport(), 0.5), vec2.mul(document.root.size, 0.5))
end
]]

function validnum(str)
    return tonumber(str) ~= nil
end

function validonlyposnum(str)
    local v = tonumber(str)
    return v ~= nil and v > 0
end

-- =====================================================

function updmdlrx(v)
    local a = math.clamp(tonumber(v), 0, 360)
    document.slidemdlrx.value = a
    document.mdlrxtext.text = "Model X rotation: " .. round(a, 4)
    globvars.model.rx = a
end

function updmdlry(v)
    local a = math.clamp(tonumber(v), 0, 360)
    document.slidemdlry.value = a
    document.mdlrytext.text = "Model Y rotation: " .. round(a, 4)
    globvars.model.ry = a
end

function updmdlrz(v)
    local a = math.clamp(tonumber(v), 0, 360)
    document.slidemdlrz.value = a
    document.mdlrztext.text = "Model Z rotation: " .. round(a, 4)
    globvars.model.rz = a
end

-- =====================================================

function updtexrx(v)
    local a = math.clamp(tonumber(v), 0, 360)
    document.slidetexrx.value = a
    document.texrxtext.text = "Texture X rotation: " .. round(a, 4)
    globvars.texture.rx = a
end

function updtexry(v)
    local a = math.clamp(tonumber(v), 0, 360)
    document.slidetexry.value = a
    document.texrytext.text = "Texture Y rotation: " .. round(a, 4)
    globvars.texture.ry = a
end