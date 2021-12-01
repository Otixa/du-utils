--@class Camera

-- Based on https://github.com/rgrams/rendercam/blob/master/rendercam/rendercam.lua

Camera = function(resolution, FOV)
    local this = {}

    local mat4 = require("cpml/mat4")
    local vec2 = require("cpml/vec2")
    local mat = mat4()

    this.Resolution = resolution or vec2(resolutionX, resolutionY)
    this.AspectRatio = this.Resolution.x / this.Resolution.y
    -- Vertical FOV
    this.FOV = 2 * math.atan(math.tan(tonumber(FOV * constants.deg2rad) * 0.5) * (this.Resolution.y / this.Resolution.x))
    this.ViewportSize = vec2(100, 100)
    this.View = nil
    this.Projection = nil

    local tan = math.tan
    local tanFov = math.tan(this.FOV / 2)
    local preCalculated = nil

    local function vecToVec4(pos)
        return {pos.x, pos.y, pos.z or 0, 1}
    end

    -- this.Projection = mat4({
    --     1 / (tanFov * this.AspectRatio), 0, 0, 0,
    --     0, 1 / tanFov, 0, 0,
    --     0, 0, -1.000002000002, -1,
    --     0, 0, 0, 1
    -- })

    local a, b, c = 1 / (tanFov * this.AspectRatio), 1 / tanFov, -1.000002000002
    local matrix = mat4({
        a, 0,  0, 0,
        0, 0, -c, 1,
        0, b,  0, 0,
        0, 0,  0, 1
    })

    local function look_at(eye, center, up)
        return matrix
    end

    this.UpdateView = function(position, forward, up)
        this.View = look_at(position, position + forward, up)
        --preCalculated = this.View * this.Projection
        preCalculated = this.View
        return this.View
    end

    this.GetMatrix = function()
        return matrix
    end

    this.TransformToViewport = function(vec4position)
        vec4position[1] = vec4position[1] / vec4position[4] * 0.5 + 0.5
        vec4position[2] = vec4position[2] / vec4position[4] * 0.5 + 0.5

        vec4position[1] = vec4position[1] * this.ViewportSize.x
        vec4position[2] = vec4position[2] * this.ViewportSize.y

        return vec3(vec4position[1], vec4position[2], vec4position[3]+1)
    end

    this.WorldToScreen = function(position)
        -- {
        --     a, 0,  0, 0,
        --     0, 0, -c, 1,
        --     0, b,  0, 0,
        --     0, 0,  0, 1
        -- }

        -- transposed
        -- {
        --     a,  0,  0, 0,
        --     0,  0,  b, 0,
        --     0, -c,  0, 0,
        --     0,  1,  0, 1
        -- }
        local x, y, z = position.x or position[1], position.y or position[2], position.z or position[3]

        --local pv = matrix * { position.x, position.y, position.z, 1 }
        local pv = { a * x, b * z, -c * y, y + 1 }

        -- Readjust into viewport space
        -- 0-100 (% for CSS) by default
        pv[1] = pv[1] / pv[4] * 0.5 + 0.5
        pv[2] = pv[2] / pv[4] * 0.5 + 0.5

        pv[1] = pv[1] * this.ViewportSize.x
        pv[2] = pv[2] * this.ViewportSize.y

        return vec3(pv[1], pv[2], pv[3]+1)
    end

    this.ScreenToWorldRay = function(position)
        -- local m = (this.Projection * this.View):invert()

        -- -- Readjust into -1 to 1 space
        -- position.x = (x - this.ViewportSize.x * 0.5) / this.ViewportSize.x * 2
        -- position.y = (y - this.ViewportSize.y * 0.5) / this.ViewportSize.y * 2

        -- nv = vecToVec4(position)
        -- fv = vecToVec4(position)
        -- local np = m * nv
        -- local fp = m * fv
        -- np = np * (1/np[1])
        -- fp = fp * (1/fp[1])
        -- return vec3(np.x, np.y, np.z), vec3(fp.x, fp.y, fp.z)
    end

    return this
end
