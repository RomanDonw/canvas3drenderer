--[[
    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at https://mozilla.org/MPL/2.0/.
]]

local obj = {}

function obj.parse(text, autofit)
    local verts = {}
    local uvs = {}
    local normals = {}

    local faces = {}
    local mtllib = nil

    for line in string.gmatch(text, "[^\r\n]+") do
        line = line:match("^%s*(.-)%s*$")
        if line ~= "" and line:sub(1, 1) ~= "#" then
            local tag, rest = line:match("^(%S+)%s*(.*)")
            if tag == "v" then
                local x, y, z = rest:match("^%s*(%S+)%s+(%S+)%s+(%S+)")
                if x ~= nil then
                    table.insert(verts, {tonumber(x), tonumber(y), tonumber(z)})
                end
            elseif tag == "vt" then
                local u, v = rest:match("^%s*(%S+)%s+(%S+)")
                if u ~= nil then
                    table.insert(uvs, {tonumber(u), 1 - tonumber(v)})
                end
            elseif tag == "mtllib" then
                mtllib = mtllib or rest:match("%S+")
            elseif tag == "vn" then
                local x, y, z = rest:match("^%s*(%S+)%s+(%S+)%s+(%S+)")
                if x ~= nil then
                    table.insert(normals, {tonumber(x), tonumber(y), tonumber(z)})
                end
            elseif tag == "f" then
                local face = {}
                for token in rest:gmatch("%S+") do
                    local vi, ti, ni = token:match("^(-?%d*)/?(-?%d*)/?(-?%d*)$")
                    vi = tonumber(vi)
                    if vi ~= nil then
                        table.insert(face, {vi, tonumber(ti) or 0, tonumber(ni) or 0})
                    end
                end
                if #face >= 3 then
                    table.insert(faces, face)
                end
            end
        end
    end

    local mesh = { vertices = {}, triangles = {}, mtllib = mtllib }

    local mapping = {}
    local hasnormals = #normals > 0

    local function resolve(vi, ti, ni)
        if vi < 0 then vi = #verts + vi + 1 end
        if ti ~= 0 then
            if ti < 0 then ti = #uvs + ti + 1 end
        end
        if ni ~= 0 then
            if ni < 0 then ni = #normals + ni + 1 end
        end

        local key = vi .. ":" .. ti .. ":" .. ni
        local idx = mapping[key]
        if idx == nil then
            local pos = verts[vi] or {0, 0, 0}
            idx = #mesh.vertices + 1
            mapping[key] = idx
            table.insert(mesh.vertices, {
                {pos[1], pos[2], pos[3]},
                uvs[ti] or {0, 0},
                hasnormals and (normals[ni] or {0, 1, 0}) or nil
            })
        end
        return idx
    end

    for _, face in ipairs(faces) do
        local indices = {}
        for _, ref in ipairs(face) do
            table.insert(indices, resolve(ref[1], ref[2], ref[3]))
        end
        for i = 2, #indices - 1 do
            table.insert(mesh.triangles, {indices[1], indices[i], indices[i + 1]})
        end
    end

    if not hasnormals then
        for _, tri in ipairs(mesh.triangles) do
            local a = mesh.vertices[tri[1]][1]
            local b = mesh.vertices[tri[2]][1]
            local c = mesh.vertices[tri[3]][1]

            local ux, uy, uz = b[1] - a[1], b[2] - a[2], b[3] - a[3]
            local vx, vy, vz = c[1] - a[1], c[2] - a[2], c[3] - a[3]

            local nx = uy * vz - uz * vy
            local ny = uz * vx - ux * vz
            local nz = ux * vy - uy * vx

            for i = 1, 3 do
                mesh.vertices[tri[i]][3] = {nx, ny, nz}
            end
        end
    end

    if autofit then
        local minx, miny, minz = math.huge, math.huge, math.huge
        local maxx, maxy, maxz = -math.huge, -math.huge, -math.huge

        for _, vert in ipairs(mesh.vertices) do
            local p = vert[1]
            if p[1] < minx then minx = p[1] end
            if p[1] > maxx then maxx = p[1] end
            if p[2] < miny then miny = p[2] end
            if p[2] > maxy then maxy = p[2] end
            if p[3] < minz then minz = p[3] end
            if p[3] > maxz then maxz = p[3] end
        end

        local cx = (minx + maxx) / 2
        local cy = (miny + maxy) / 2
        local cz = (minz + maxz) / 2

        local size = math.max(maxx - minx, maxy - miny, maxz - minz)
        local scale = size > 0 and (1 / size) or 1

        for _, vert in ipairs(mesh.vertices) do
            local p = vert[1]
            p[1] = (p[1] - cx) * scale
            p[2] = (p[2] - cy) * scale
            p[3] = (p[3] - cz) * scale
        end
    end

    mesh.cullsign = obj.cull_sign(mesh)

    return mesh
end

function obj.load(path, autofit)
    if not file.exists(path) then return nil end
    return obj.parse(file.read(path), autofit)
end

-- Determines the winding sign so that a cross-product normal points outward:
-- majority vote between cross-product normals and the mesh's own normals.
-- Returns +1 or -1.
function obj.cull_sign(mesh)
    local sign = 0
    for _, tri in ipairs(mesh.triangles) do
        local a = mesh.vertices[tri[1]][1]
        local b = mesh.vertices[tri[2]][1]
        local c = mesh.vertices[tri[3]][1]

        local ux, uy, uz = b[1] - a[1], b[2] - a[2], b[3] - a[3]
        local vx, vy, vz = c[1] - a[1], c[2] - a[2], c[3] - a[3]

        local nx = uy * vz - uz * vy
        local ny = uz * vx - ux * vz
        local nz = ux * vy - uy * vx

        local n0 = mesh.vertices[tri[1]][3]
        local n1 = mesh.vertices[tri[2]][3]
        local n2 = mesh.vertices[tri[3]][3]

        if n0 ~= nil and n1 ~= nil and n2 ~= nil then
            local ax = (n0[1] + n1[1] + n2[1]) / 3
            local ay = (n0[2] + n1[2] + n2[2]) / 3
            local az = (n0[3] + n1[3] + n2[3]) / 3
            sign = sign + (nx * ax + ny * ay + nz * az > 0 and 1 or -1)
        end
    end
    return sign >= 0 and 1 or -1
end

local function objdir(path)
    local dir = path:match("^(.*)/[^/]+$")
    if dir then return dir end
    local prefix = path:match("^(%a+):")
    return prefix and (prefix .. ":") or ""
end

local function joinpath(dir, name)
    if dir:sub(-1) == ":" then return dir .. name end
    return dir .. "/" .. name
end

-- Returns the path of the first map_Kd texture referenced by the model's MTL.
function obj.map_kd_path(objpath, mesh)
    local mtllib = mesh and mesh.mtllib
    if mtllib == nil then return nil end

    local dir = objdir(objpath)
    local mtlpath = joinpath(dir, mtllib)
    if not file.exists(mtlpath) then return nil end

    local map_kd = nil
    for line in string.gmatch(file.read(mtlpath), "[^\r\n]+") do
        local tag, rest = line:match("^%s*(%S+)%s*(.*)")
        if tag == "map_Kd" or tag == "map_Kd_rgb" then
            map_kd = rest:match("%S+")
            break
        end
    end

    if map_kd == nil then return nil end
    return joinpath(dir, map_kd)
end

local texcounter = 0

-- Loads the model's diffuse texture and returns {data, w, h} or nil.
function obj.load_texture(objpath, mesh)
    local texpath = obj.map_kd_path(objpath, mesh)
    if texpath == nil or not file.exists(texpath) then return nil end

    texcounter = texcounter + 1
    local texname = "canvas3d_model_tex_" .. texcounter

    local ok = pcall(function()
        assets.load_texture(file.read_bytes(texpath), texname, "png")
    end)
    if not ok then return nil end

    local canvas = assets.to_canvas(texname)
    if canvas == nil then return nil end

    return { data = canvas:get_data(), w = canvas.width, h = canvas.height }
end

return obj
