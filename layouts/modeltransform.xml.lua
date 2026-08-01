--[[
    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at https://mozilla.org/MPL/2.0/.
]]

require "globvars"
local obj = require "obj"

function on_open()
    document.currentmodel.text = "Model: " .. globvars.model.name
    refresh_models()

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
    
    updtexrot(globvars.texture.rot)

    document.slidetexsx.text = "" .. globvars.texture.sx
    document.slidetexsy.text = "" .. globvars.texture.sy
end

function luaesc(str)
    return str:gsub("\\", "\\\\"):gsub('"', '\\"')
end

function xmlesc(str)
    return str:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
end

function modelname(path)
    local name = file.name(path)
    name = name:match("^(.*)%.[^%.]+$") or name
    return name
end

function isobj(path)
    local name = file.name(path)
    return name:lower():sub(-4) == ".obj"
end

function refresh_models()
    local list = document.modellist
    list:clear()

    local items = {}
    local ok, entries = pcall(file.list, "export:")
    if not ok or entries == nil or #entries == 0 then
        ok, entries = pcall(file.list, "export:/")
    end
    if ok and entries ~= nil then
        for _, p in ipairs(entries) do
            p = p:gsub(":/+", ":")
            if file.isfile(p) and isobj(p) then
                table.insert(items, p)
            end
        end
    end

    table.sort(items)

    for _, p in ipairs(items) do
        list:add(gui.template("model_item", {
            path = luaesc(p),
            name = xmlesc(modelname(p))
        }))
    end
end

function select_model(path)
    local mesh = obj.load(path, globvars.model.autofit)
    if mesh == nil then
        console.chat("failed to load model: " .. path)
        return
    end

    globvars.model.path = path
    globvars.model.name = modelname(path)
    globvars.model.mesh = mesh
    globvars.model.tex = obj.load_texture(path, mesh)

    document.currentmodel.text = "Model: " .. globvars.model.name
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

function updtexrot(v)
    local a = math.clamp(tonumber(v), 0, 360)
    document.slidetexrot.value = a
    document.texrottext.text = "Texture rotation: " .. round(a, 4)
    globvars.texture.rot = a
end