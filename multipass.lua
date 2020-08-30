lpad = function(str, len, char)
    if char == nil then char = ' ' end
    return string.rep(char, len - #str)..str
end

MultiPass_runner = function(prefix, startval, blocksize)

    local foundIds = {}
    local last = startval+blocksize
    local loopLength = 0
    for c=startval,last,1 do
       
        local hexval = string.format("%x", c)
        local outstring = prefix..lpad(hexval,10, "0").."0"
        local class = _NQ_execute_method(outstring, "getElementClass")
        if class ~= null then table.insert(foundIds, outstring) end
        
        loopLength = loopLength+1
        if loopLength == 4000 then
            loopLength = 0
            coroutine.yield(true,c)
        end

    end

    return false,foundIds
end

MultiPass = (function(startval, endval, threads, prefix)

    local self = {}
    self.Threads = threads
    self.Coroutines = {}

    local blockSize = (endval-startval)/self.Threads

    for thread=1,self.Threads,1 do
        local threadStartNumber = startval + (blockSize*thread)
        local t = coroutine.create(MultiPass_runner)
        table.insert(self.Coroutines, t)
        coroutine.resume(t, prefix, threadStartNumber, blockSize)
    end

    function self.Update()
        for thread=1,self.Threads,1 do
            local threadStatus = coroutine.status(self.Coroutines[thread])
            if threadStatus == "suspended" then 
                local status,continue,ret = coroutine.resume(self.Coroutines[thread]) 
                if not continue then
                    for k in ret do
                        system.print("Found "..k)
                    end
                else
                    system.print("Thread "..thread.." at "..ret)
                end
            end
        end
    end

    return self
end)(0,4294967295,2,"Unit_25")
--Unit_25a7b23b300