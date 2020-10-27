--@class Utils3D

Utils3d = (function ()
    local this = {}

    function this.worldToLocal(pos, up, right, forward)
        return vec3(
            library.systemResolution3(
                {right:unpack()},
                {forward:unpack()},
                {up:unpack()},
                {pos:unpack()}
            )
        )
    end

    function this.localToRelative(pos, up, right, forward)
        -- this is horrible, can optimize?
        local rightX, rightY, rightZ = right:unpack()
        local forwardX, forwardY, forwardZ = forward:unpack()
        local upX, upY, upZ = up:unpack()
        local rfuX, rfuY, rfuZ = pos:unpack()
        local relX = rfuX * rightX + rfuY * forwardX + rfuZ * upX
        local relY = rfuX * rightY + rfuY * forwardY + rfuZ * upY
        local relZ = rfuX * rightZ + rfuY * forwardZ + rfuZ * upZ
        return vec3(relX, relY, relZ)
    end

    function this.worldToScreen(selfPos, targetPos, forward, up)
        -- see https://github.com/rgrams/rendercam/blob/master/rendercam/rendercam.lua for ideas

        local P = mat4():perspective(48, 1920/1080, 0.1, 100000)
        local V = mat4():look_at(selfPos, selfPos + forward, up)

        -- try P * V * pos
        local pos = V * P * { selfPos.x, selfPos.y, selfPos.z, 1 }

        -- try pos = pos * (1/pos[4])
        pos[1] = pos[1] / pos[4] * 0.5 + 0.5
        pos[2] = pos[2] / pos[4] * 0.5 + 0.5

        pos[1] = pos[1] * 100
        pos[2] = pos[2] * 100

        return vec3(pos[1], pos[2], pos[3])
    end

    return this
end)()