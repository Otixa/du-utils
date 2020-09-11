BrakingCalculator = (function()
    local internal = {BrakingDistance = -1, BrakingTime = -1, thread=nil}
    local this = {Debug = false}

    function this.Recalculate(mass, velocity, force)

        local c = 8333.34
        local cV = velocity
        local cD = 0
        local cT = 0
        
        local tStep = 5
        local cSteps = 0
        local mSteps = 500

        while cV > 0 and cSteps<mSteps do
            if this.Debug then system.print("Step "..cSteps) end

            local relativisticMultiplier = 1 / math.sqrt(1 - cV^2 / c^2);
            if this.Debug then system.print("rM "..relativisticMultiplier) end
            local relativisticMass = mass * relativisticMultiplier;
            if this.Debug then system.print("rmass "..relativisticMass) end
            local accel = force / relativisticMass;
            if this.Debug then system.print("accel "..accel) end
            local deltaV = accel * tStep;
            if this.Debug then system.print("deltaV "..deltaV) end
            
            cV = cV - deltaV;
            cT = cT + tStep;
            cD = cD + (cV + (deltaV / 2)) * tStep;

            cSteps = cSteps+1
            if this.Debug then system.print("Stepping") end
            coroutine.yield(false)
        end

        if cV <= 0 then
            coroutine.yield(true, {cD, cT})
        end

    end

    function this.Update(mass, velocity, force)

        if internal.thread == nil then
            if this.Debug then system.print("Starting new thread") end
            internal.thread = coroutine.create(this.Recalculate)
            coroutine.resume(internal.thread, mass, velocity, force)
        end

        local threadStatus = coroutine.status(internal.thread)
        if this.Debug then system.print("Thread is "..threadStatus) end

        if threadStatus == "suspended" then
            if this.Debug then system.print("Thread yielded") end
            local ignore, finished, data = coroutine.resume(internal.thread)
            if this.Debug then system.print("Thread finished? "..tostring(finished)) end
            if finished then
                if this.Debug then system.print("Thread finished with data "..data[1].." "..data[2]) end
                internal.BrakingDistance = data[1] 
                internal.BrakingTime = data[2] 
            end
        elseif threadStatus == "dead" then
            internal.thread = nil
        end

    end

    function this.GetBrakingDistance()
        return internal.BrakingDistance
    end
    function this.GetBrakingTime()
        return internal.BrakingTime
    end

    return this
end)()