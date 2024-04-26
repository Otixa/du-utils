--@class PWM

PWM = (function(hz, duty)
    hz = 1 / hz
    local this = {}
    this.Time = system.getArkTime()
    this.GetState = function()
        this.Time = system.getArkTime()
        local span = this.Time % hz
        if span >= (hz * duty) then
        	return false
        end
        return true
    end

    return this
end)