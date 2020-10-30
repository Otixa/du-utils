--@class UnitConversion

function UnitConversion()
    local self = {}

    local siUnits = {
        {Name="Giga", Suffix="G", Value="1000000000"},
        {Name="Mega", Suffix="M", Value="1000000"},
        {Name="Kilo", Suffix="K", Value="1000"},
        {Name="Uni", Suffix="", Value="1"},
        {Name="Centi", Suffix="c", Value="0.01"},
    }

    function self.SIConversion(value, suffix)
        for i=1,#siUnits do
            local siUnit = siUnits[i]
            local val = value/siUnit.Value
            if val > 1 then return string.format("%s%s%s", val, siUnit.Suffix, suffix) end
        end
        return string.format("%s%s%s", val, "", suffix)
    end

    function self.VariableDistance(input)
        local self = {Value = input}
        local mt = {
            __tostring = function(t) 
                local v = t.Value
                local suffix = "m"
                if v > 200000 then v = v/200000 suffix = "su"
                elseif v > 1000 then v = v/1000 suffix = "km" end
                return utils.round(v,0.1)..suffix
            end,
            __add = function(t, v) if type(t)=="table" then return t.Value+v else return v.Value+t end end,
            __sub = function(t, v)  if type(t)=="table" then return t.Value-v else return v.Value-t end end,
            __mul = function(t, v)  if type(t)=="table" then return t.Value*v else return v.Value*t end end,
            __div = function(t, v)  if type(t)=="table" then return t.Value/v else return v.Value/t end end,
            __pow = function(t, v)  if type(t)=="table" then return t.Value^v else return v.Value^t end end,
            __lt = function(t, v)  if type(t)=="table" then return t.Value<v else return v.Value<t end end,
            __le = function(t, v)  if type(t)=="table" then return t.Value<=v else return v.Value<=t end end,
        }
        setmetatable(self, mt)
        return self
    end
    function self.VariableVelocity(input)
        local self = {Value = input}
        local mt = {
            __tostring = function(t) 
                local v = t.Value
                local suffix = "m/s"
                if v > 200000 then v = v/200000 suffix = "su/s"
                elseif v > 1000 then v = v/1000 suffix = "km/s" end
                return utils.round(v,0.1)..suffix
            end,
            __add = function(t, v) if type(t)=="table" then return t.Value+v else return v.Value+t end end,
            __sub = function(t, v)  if type(t)=="table" then return t.Value-v else return v.Value-t end end,
            __mul = function(t, v)  if type(t)=="table" then return t.Value*v else return v.Value*t end end,
            __div = function(t, v)  if type(t)=="table" then return t.Value/v else return v.Value/t end end,
            __pow = function(t, v)  if type(t)=="table" then return t.Value^v else return v.Value^t end end,
            __lt = function(t, v)  if type(t)=="table" then return t.Value<v else return v.Value<t end end,
            __le = function(t, v)  if type(t)=="table" then return t.Value<=v else return v.Value<=t end end,
        }
        setmetatable(self, mt)
        return self
    end

    function self.TimeConversion(seconds)
        local ret = {
            Months = 0,
            Days = 0,
            Hours = 0,
            Minutes = 0,
            Seconds = 0,
        }
        local mt = {
            __tostring = function(self)
                local ret = ""
                if self.Months > 0 then ret = ret .. self.Months .. " Months " end
                if self.Days > 0 then ret = ret .. self.Days .. " Days " end
    
                local hours_pad = self.Hours
                if #tostring(hours_pad)<2 then hours_pad = "0"..hours_pad end
                local minutes_pad = self.Minutes
                if #tostring(minutes_pad)<2 then minutes_pad = "0"..minutes_pad end
                local seconds_pad = self.Seconds
                if #tostring(seconds_pad)<2 then seconds_pad = "0"..seconds_pad end
    
                ret = ret .. string.format(" %s:%s:%s", hours_pad, minutes_pad, seconds_pad)
                return ret
            end
        }
        setmetatable(ret, mt)
        ret.Months = math.floor(seconds/2592000)
        seconds = seconds % 2592000
        ret.Days = math.floor(seconds/86400)
        seconds = seconds % 86400
        ret.Hours = math.floor(seconds / 3600)
        seconds = seconds % 3600
        ret.Minutes = math.floor(seconds/60)
        ret.Seconds = Utilities.Round(seconds % 60,0)
        return ret
    end



    return self
end

unitconverter = UnitConversion()
