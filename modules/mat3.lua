local mat3 = {}

function mat3.mul(a, b)
    if #a < 9 then error("first argument must be 3x3 matrix") end

    if #b >= 9 then
        --[[
                                | b[1] b[2] b[3] |
                                | b[4] b[5] b[6] |
                                | b[7] b[8] b[9] |

            | a[1] a[2] a[3] |  | v11  v12  v13  |
            | a[4] a[5] a[6] |  | v21  v22  v23  |
            | a[7] a[8] a[9] |  | v31  v32  v33  |
        ]]

        local v11 = a[1] * b[1] + a[2] * b[4] + a[3] * b[7]
        local v12 = a[1] * b[2] + a[2] * b[5] + a[3] * b[8]
        local v13 = a[1] * b[3] + a[2] * b[6] + a[3] * b[9]

        local v21 = a[4] * b[1] + a[5] * b[4] + a[6] * b[7]
        local v22 = a[4] * b[2] + a[5] * b[5] + a[6] * b[8]
        local v23 = a[4] * b[3] + a[5] * b[6] + a[6] * b[9]

        local v31 = a[7] * b[1] + a[8] * b[4] + a[9] * b[7]
        local v32 = a[7] * b[2] + a[8] * b[5] + a[9] * b[8]
        local v33 = a[7] * b[3] + a[8] * b[6] + a[9] * b[9]

        return
        {
            v11, v12, v13,
            v21, v22, v23,
            v31, v32, v33
        }
    elseif #b >= 3 then
        local x = a[1] * b[1] + a[2] * b[1] + a[3] * b[1]
        local y = a[4] * b[2] + a[5] * b[2] + a[6] * b[2]
        local z = a[7] * b[3] + a[8] * b[3] + a[9] * b[3]
        return {x, y, z}
    else
        error("incorrect second argument length")
    end
end

function mat3.build(v1, v2, v3)
    return
    {
        v1[1], v2[1], v3[1],
        v1[2], v2[2], v3[2],
        v1[3], v2[3], v3[3]
    }
end

function mat3.rotate(angle)
    angle = math.rad(angle)
    return
    {
        math.cos(angle), -math.sin(angle), 0,
        math.sin(angle), math.cos(angle), 0,
        0, 0, 1
    }
end

function mat3.scale(scale)
    return
    {
        scale[1], 0, 0,
        0, scale[2], 0,
        0, 0, 1
    }
end

function mat3.translate(offset)
    return
    {
        1, 0, offset[1],
        0, 1, offset[2],
        0, 0, 1
    }
end

function mat3.transpose(mat)
    return
    {
        mat[1], mat[4], mat[7],
        mat[2], mat[5], mat[8],
        mat[3], mat[6], mat[9]
    }
end



return mat3