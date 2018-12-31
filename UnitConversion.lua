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

    function self.TimeConversion(seconds)
        local ret = {
            Months = 0,
            Days = 0,
            Hours = 0,
            Minutes = 0,
            Seconds = 0,
        }
        ret.__index = ret
        function ret:__tostring()
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

        ret.Months = math.floor(seconds/2592000)
        seconds = seconds % 2592000
        ret.Days = math.floor(seconds/86400)
        seconds = seconds % 86400
        ret.Hours = math.floor(seconds / 3600)
        seconds = seconds % 3600
        ret.Minutes = math.floor(seconds/60)
        ret.Seconds = seconds % 60

        return ret
    end



    return self
end

unitconverter = UnitConversion()