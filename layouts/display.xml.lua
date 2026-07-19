--[[
    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at https://mozilla.org/MPL/2.0/.
]]

-- ========================== SETTINGS ==========================

local near = 0.05
local far = 1000
local texturename = "debugtexture"

local shininess = 32
local ambientlight = {0.2, 0.2, 0.2}
local lights = {
    {{3, 3, 3}, 9, {13 / 15, 10 / 15, 2 / 15}},
    {{3, 3, -3}, 14, {0, 0, 1}}
}

local model = {
    vertices = {
        {{-0.5, -0.5, -0.5}, {0, 0}, {-1, -1, -1}},
        {{-0.5, -0.5, 0.5}, {0, 1}, {-1, -1, 1}},
        {{0.5, -0.5, -0.5}, {1, 0}, {1, -1, -1}},
        {{0.5, -0.5, 0.5}, {1, 1}, {1, -1, 1}},

        {{0, 0.5, 0}, {0.5, 0.5}, {0, 1, 0}}
    },
    triangles = {
        {1, 2, 4},
        {4, 3, 1},

        {3, 5, 1},
        {4, 5, 3},
        {2, 5, 4},
        {1, 5, 2}
    }
}

-- ==============================================================

local testtex = nil
local testtexdata = nil

function on_open()
    testtex = assets.to_canvas(texturename)

    if testtex ~= nil then
        testtexdata = testtex:get_data()
        console.chat("successfully loaded texture")

        events.on(PACK_ID .. ":on_hud_render", on_render)
    end
end

function on_render()
    local winsz = gui.get_viewport()

    if winsz[1] <= 0 or winsz[2] <= 0 then
        document.canvas.data:clear(0)
        return
    end

    document.root.wpos = {0, 0}
    document.root.size = winsz

    document.canvas.wpos = {0, 0}
    document.canvas.size = winsz

    local cam = cameras.get(player.get_camera(hud.get_player()))
    local campos = cam:get_pos()

    local projmat = mat4.perspective(cam:get_fov(), winsz[1] / winsz[2], near, far)
    local viewmat = mat4.look_at(campos, vec3.add(campos, cam:get_front()), cam:get_up())
   
    --[[
    local modlmat = mat4.mul(
        mat4.rotate({0, 1, 0}, math.fmod(time.uptime() * 45, 360)),
        mat4.translate({0, 2 + math.sin(time.uptime()), 0})
    )
    ]]

    local modlmat = mat4.idt()
    mat4.mul(modlmat, mat4.translate({0, 2, 0}), modlmat)
    mat4.mul(modlmat, mat4.rotate({0, 1, 0}, math.fmod(time.uptime() * 45 * 2, 360)), modlmat)
    mat4.mul(modlmat, mat4.rotate({1, 0, 0}, math.fmod(time.uptime() * 45 * 2.5, 360)), modlmat)
    mat4.mul(modlmat, mat4.scale({1.5, 1.5, 1.5}), modlmat)

    --local modlmat = mat4.translate({0, 2 + math.sin(time.uptime()), 0})
    

    local mvpmat = mat4.mul(projmat, mat4.mul(viewmat, modlmat))

    document.canvas.data:clear(0)

    local cdata = document.canvas.data:get_data()

    rendermesh(model, mvpmat, U32view(cdata), winsz, U32view(testtexdata), 16, 16, campos, modlmat)

    document.canvas.data:set_data(cdata)
end

function project(point, mvpmat, winsz)
   local clipvec = mat4.mul(mvpmat, point)
   if clipvec[4] <= 0 then return nil end

   return {
       (1 + clipvec[1] / clipvec[4]) * 0.5 * winsz[1],
       (1 - clipvec[2] / clipvec[4]) * 0.5 * winsz[2],
       (1 + clipvec[3] / clipvec[4]) * 0.5
   }
end

function hsv2rgb(h, s, v)
    h = math.fmod(h, 360) -- maybe optimize it.
    s = math.clamp(s, 0, 1) * 100
    v = math.clamp(v, 0, 1) * 100

    local hi = math.fmod(math.floor(h / 60), 6)
    local vmin = ((100 - s) * v) / 100
    local a = (v - vmin) * (math.fmod(h, 60) / 60)

    local vinc = math.floor((vmin + a) * 2.56)
    local vdec = math.floor((v - a) * 2.56)
    v = math.floor(v * 2.56)
    vmin = math.floor(vmin * 2.56)

    if hi == 0 then
        return {v, vinc, vmin}
    elseif hi == 1 then
        return {vdec, v, vmin}
    elseif hi == 2 then
        return {vmin, v, vinc}
    elseif hi == 3 then
        return {vmin, vdec, v}
    elseif hi == 4 then
        return {vinc, vmin, v}
    elseif hi == 5 then
        return {v, vmin, vdec}
    end
    return nil
end

function getbarycoords(a, b, c, p)
    local doublearea = math.abs((b[1] - a[1]) * (c[2] - a[2]) - (c[1] - a[1]) * (b[2] - a[2]))
    if doublearea == 0 then return nil end

    return {
        ((b[1] - p[1]) * (c[2] - p[2]) - (c[1] - p[1]) * (b[2] - p[2])) / doublearea,
        ((c[1] - p[1]) * (a[2] - p[2]) - (a[1] - p[1]) * (c[2] - p[2])) / doublearea,
        ((a[1] - p[1]) * (b[2] - p[2]) - (b[1] - p[1]) * (a[2] - p[2])) / doublearea
    }
end

function ispointin2dtriangle(v1, v2, v3, p)
    local c = getbarycoords(v1, v2, v3, p)
    if c == nil then return false end

    return c[1] >= 0 and c[1] <= 1 and c[2] >= 0 and c[2] <= 1 and c[3] >= 0 and c[3] <= 1
end

function get2dtriangleAABB(a, b, c)
    return {
        {math.min(a[1], b[1], c[1]), math.min(a[2], b[2], c[2])},
        {math.max(a[1], b[1], c[1]), math.max(a[2], b[2], c[2])}
    }
end

function rendertriangle(c, winsz, tex, texw, texh, campos, v1, v2, v3, p1, p2, p3)
    local min, max = unpack(get2dtriangleAABB(p1, p2, p3))

    min = {math.clamp(min[1], 0, winsz[1]), math.clamp(min[2], 0, winsz[2])}
    max = {math.clamp(max[1], 0, winsz[1]), math.clamp(max[2], 0, winsz[2])}
    
    for j = math.floor(min[2]), math.ceil(max[2]) do
        for i = math.floor(min[1]), math.ceil(max[1]) do
            local bc = getbarycoords(p1, p2, p3, {i, j})
            if bc ~= nil and bc[1] >= 0 and bc[1] <= 1 and bc[2] >= 0 and bc[2] <= 1 and bc[3] >= 0 and bc[3] <= 1 then
                local x = bc[1] * v1[1][1] + bc[2] * v2[1][1] + bc[3] * v3[1][1]
                local y = bc[1] * v1[1][2] + bc[2] * v2[1][2] + bc[3] * v3[1][2]
                local z = bc[1] * v1[1][3] + bc[2] * v2[1][3] + bc[3] * v3[1][3]

                local fragpos = {x, y, z}

                local u = bc[1] * v1[2][1] + bc[2] * v2[2][1] + bc[3] * v3[2][1]
                local v = bc[1] * v1[2][2] + bc[2] * v2[2][2] + bc[3] * v3[2][2]

                u = (u - math.floor(u))
                v = (v - math.floor(v))

                local nx = bc[1] * v1[3][1] + bc[2] * v2[3][1] + bc[3] * v3[3][1]
                local ny = bc[1] * v1[3][2] + bc[2] * v2[3][2] + bc[3] * v3[3][2]
                local nz = bc[1] * v1[3][3] + bc[2] * v2[3][3] + bc[3] * v3[3][3]

                local fragnormal = vec3.normalize({nx, ny, nz})

                local color = {0, 0, 0, 0}

                -- ==============================================================
                
                local resultlight = {0, 0, 0}
                
                for li = 1, #lights do
                    local lightdata = lights[li]

                    local distcolor = vec3.mul(lightdata[3], (1 - math.min(1, vec3.distance(fragpos, lightdata[1]) / lightdata[2])))
                    local lightdir = vec3.normalize(vec3.sub(lightdata[1], fragpos))

                    local diffcoefficient = math.max(vec3.dot(fragnormal, lightdir), 0)
                    local diffcolor = vec3.mul(distcolor, diffcoefficient)

                    local viewdir = vec3.normalize(vec3.sub(campos, fragpos))
                    local halfwaydir = vec3.normalize(vec3.add(lightdir, viewdir))
                    local speccolor = vec3.mul(distcolor, math.max(vec3.dot(fragnormal, halfwaydir), 0) ^ shininess)

                    vec3.add(resultlight, vec3.add(diffcolor, speccolor), resultlight)
                end
                vec3.add(resultlight, ambientlight, resultlight)

                vec4.div(unpackRGBA(tex[math.floor(v * texh) * texw + math.floor(u * texw) + 1]), 255, color)
                vec4.mul(color, {resultlight[1], resultlight[2], resultlight[3], 1}, color)

                -- ==============================================================
                
                vec4.mul({math.clamp(color[1], 0, 1), math.clamp(color[2], 0, 1), math.clamp(color[3], 0, 1), math.clamp(color[4], 0, 1)}, 255, color)
                c[j * winsz[1] + i] = packRGBA(math.round(color[1]), math.round(color[2]), math.round(color[3]), math.round(color[4]))
            end
        end
    end
end

function packRGBA(r, g, b, a)
    return bit.band(bit.bor(bit.band(r, 0xFF), bit.lshift(bit.band(g, 0xFF), 8), bit.lshift(bit.band(b, 0xFF), 16), bit.lshift(bit.band(a, 0xFF), 24)), 0xFFFFFFFF)
end

function unpackRGBA(rgba)
    return {
        bit.band(rgba, 0xFF),
        bit.band(bit.rshift(rgba, 8), 0xFF),
        bit.band(bit.rshift(rgba, 16), 0xFF),
        bit.band(bit.rshift(rgba, 24), 0xFF)
    }
end

function rendermesh(mesh, mvpmat, canvas, winsz, tex, texw, texh, campos, modelmat)
    local points = {}
    local verts = {}

    for i = 1, #mesh.vertices do
        local point = project(mesh.vertices[i][1], mvpmat, winsz)
        if point == nil then return end
        table.insert(points, point)

        table.insert(verts, {
            mat4.mul(modelmat, mesh.vertices[i][1]),
            mesh.vertices[i][2],
            mat4.mul(modelmat, mesh.vertices[i][3]),
        })
    end

    for i = 1, #mesh.triangles do
        local tri = mesh.triangles[i]

        -- optimize it without using 'goto' keyword.
        if tri[1] < 1 or tri[1] > #mesh.vertices or
            tri[2] < 1 or tri[2] > #mesh.vertices or
            tri[3] < 1 or tri[3] > #mesh.vertices then
            goto continue
        end
        
        rendertriangle(canvas, winsz, tex, texw, texh, campos, verts[tri[1]], verts[tri[2]], verts[tri[3]], points[tri[1]], points[tri[2]], points[tri[3]])

        ::continue::
    end
end

function ispointinwin(winsz, point)
    return point[1] >= 0 and point[2] >= 0 and point[1] < winsz[1] and point[2] < winsz[2]
end

function map(norm, start, _end)
    return norm * (_end - start) + start
end
