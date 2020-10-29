--@class ConfigSerializer

local typeof = require("pl/types").type
local json = require("dkjson")
local vec2 = require("cpml/vec2")

ConfigHint = function()
    local this = {}
    this.Type = "Unknown"
    setmetatable(this, { _name = "ConfigHint" })
    -- Validate an input, return validation state and throw error if invalid.
    this.Validate = function(val) return true end
    this.Save = function(val) return val end
    this.Load = function(val) return val end
    return this
end

IntHint = function(step, min, max)
    local this = ConfigHint()
    this.Type = "Int"
    this.Step = step or 1
    this.Min = min
    this.Max = max
    this.Validate = function(val)
        assert(math.type(val) == "integer", "Value is not an integer")
        return true
    end
    this.Save = function(val) return tonumber(val) end
    this.Load = function(val) return tonumber(val) end
    return this
end

FloatHint = function(step, min, max)
    local this = ConfigHint()
    this.Type = "Float"
    this.Step = step or 0.1
    this.Min = min
    this.Max = max
    this.Validate = function(val)
        assert(math.type(val) == "float", "Value is not a float")
        return true
    end
    this.Save = function(val) return tonumber(val) end
    this.Load = function(val) return tonumber(val) end
    return this
end

BoolHint = function()
    local this = ConfigHint()
    this.Type = "Bool"
    this.Validate = function(val)
        assert(math.type(val) == "boolean", "Value is not a boolean")
        return true
    end
    this.Save = function(val) return val == true end
    this.Load = function(val) return val == true end
    return this
end

StringHint = function()
    local this = ConfigHint()
    this.Type = "String"
    this.Validate = function(val)
        assert(type(val) == "string", "Value is not a string")
        return true
    end
    this.Save = function(val) return tostring(val) end
    this.Load = function(val) return tostring(val) end
    return this
end

Vec2Hint = function()
    local this = ConfigHint()
    this.Type = "Vec2"
    this.Validate = function(val)
        assert(vec3.isvector(val) == true, "Value is not a vec2")
        return true
    end
    this.Save = function(val) return {val.x, val.y} end
    this.Load = function(val) return vec2(val) end
    return this
end

Vec3Hint = function()
    local this = ConfigHint()
    this.Type = "Vec3"
    this.Validate = function(val)
        assert(vec3.isvector(val) == true, "Value is not a vec3")
        return true
    end
    this.Save = function(val) return {val.x, val.y, val.z} end
    this.Load = function(val) return vec3(val) end
    return this
end

ConfigValue = function(value, hint)
    local this = {}
    this.Value = value
    setmetatable(this, { _name = "ConfigValue" })

    local function loadType(value)
        if hint and typeof(hint) == "ConfigHint" then
            this.Hint = hint
        elseif hint == nil then
            if type(value) == "number" then
                if math.type(value) == "float" then
                    this.Hint = FloatHint()
                elseif math.type(value) == "integer" then
                    this.Hint = IntHint()
                end
            elseif type(value) == "boolean" then
                this.Hint = BoolHint()
            elseif value.x and value.y and value.z then
                this.Hint = Vec3Hint()
            elseif value.x and value.y then
                this.Hint = Vec2Hint()
            elseif type(value) == "table" then
                -- return the table, I guess?
                error("ConfigHint provided is a wrong type ("..type(hint)..")")
            elseif type(value) == "string" then
                this.Hint = StringHint()
            else
                error("ConfigHint provided is a wrong type ("..type(hint)..")")
            end
        else
            error("ConfigHint provided is a wrong type ("..type(hint)..")")
        end
    end

    loadType(value)

    this.Load = function(value)
        loadType(value)
        this.Value = this.Hint.Load(value)
    end

    this.Save = function()
        return this.Hint.Save(this.Value)
    end

    return this
end

ConfigSerializer = (function()
    local this = {}

    this.Serialize = function(value)
        local output = {}
        for k,v in pairs(value) do
            if typeof(v) == "ConfigValue" then
                output[k] = v.Save()
            else
                output[k] = ConfigValue(v).Save()
            end
        end
        return json.encode(output)
    end

    this.Deserialize = function(jsonString)
        local output = {}
        local val = json.decode(jsonString)
        for k,v in pairs(val) do
            output[k] = ConfigValue(v)
        end
        return output
    end

    return this
end)()
