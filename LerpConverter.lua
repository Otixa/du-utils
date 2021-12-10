--@class LerpConverter

---Utility for converting 6DOF axis into a lerped vec3
---@class LerpConverter
LerpConverter = function(xNeg, xPos, yNeg, yPos, zNeg, zPos)
    ---@type LerpConverter
    local this = {}
    this.x = {xNeg, xPos}
    this.y = {yNeg, yPos}
    this.z = {zNeg, zPos}

    local zero = vec3(0,0,0)

    local function lerp(a,b,t)
        return a * (1-t) + b * t
    end

    local function getAxisSide(neg, pos, value)
        if value == 0 then
            return zero
        else
            if value > 0 then
                return lerp(zero, pos, value)
            else
                return lerp(zero, neg, -value)
            end
        end
    end

    ---Multiply the converter values by a kinematics table
    ---@param kinematics MaxKinematicsModel
    this.MultiplyKinematics = function (kinematics)
        return LerpConverter(
            xNeg * kinematics.Left, xPos * kinematics.Right,
            yNeg * kinematics.Backward, yPos * kinematics.Forward,
            zNeg * kinematics.Down, zPos * kinematics.Up
        )
    end

    ---Creates a LerpConverter from 3 axis vectors
    ---@param right vec3 Right axis
    ---@param forward vec3 Forward axis
    ---@param up vec3 Up axis
    this.FromAxis = function(right, forward, up)
        return LerpConverter(-right, right, -forward, forward, -up, up)
    end

    ---Transforms a vec3 into a vec3 lerped between the 6DOF values
    ---@param vector vec3 The desired directions
    ---@return vec3
    this.Transform = function(vector)
        local x = getAxisSide(xNeg, xPos, vector.x)
        local y = getAxisSide(yNeg, yPos, vector.y)
        local z = getAxisSide(zNeg, zPos, vector.z)

        return x+y+z
    end

    return this
end