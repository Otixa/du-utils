--@class Communication

local function trim(s)
    local from = s:match"^%s*()"
    return from > #s and "" or s:match(".*%S", from)
 end

 local function split(s, delimiter)
    idx = 1
    result = {}
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        result[idx] = match
        idx = idx + 1
    end
    return result
end

RPC = function(comm)
    local this = {}
    this.Communication = comm

    --- ST Open Protocol, ST Encrypted Message
    this.HSK = function(transportType)
        local trans = comm.CurrentTransport
        if trans.IsInitialized then
            return
        end
        if this.Communication.SwitchTransport(transportType) then
            return this.Communication.Send("HSKA", trans.Init() .. " " .. tostring(trans.Begin())) 
        else
            error("Unsupported transport: " .. transportType)
            -- error out with not supported transport
        end
    end

    this.HSKA = function(payload)
        local trans = this.Communication.CurrentTransport
        if trans.IsInitialized then
            return
        end
        if payload then
            payload = split(payload, " ")
            local initKey = payload[1]
            local pub = payload[2]
            local n = trans.Init(initKey)

            local myKey = trans.Begin()
            local retn = this.Communication.Send("HSKB", n  .. " " .. tostring(myKey))
            trans.IsInitialized = true
            trans.Begin(pub)
            trans.Finalize()
            return retn
        else
            error("morp")
            -- u wot m8?
        end
    end

    this.HSKB = function(payload)
        local trans = this.Communication.CurrentTransport
        if trans.IsInitialized then
            return
        end
        if payload then
            payload = split(payload, " ")
            local initKey = payload[1]
            local pub = payload[2]
            trans.Begin(pub)
            trans.IsInitialized = true
            trans.Finalize()
        else
            error("morp")
            -- u wot m8?
        end
    end

    this.MSG = function(payload)
        system.print(string.format("[%s] Message: %s", comm.TargetId, payload))
    end

    this.DISC = function(payload)
        system.print(string.format("[%s] Disconnected: %s", comm.TargetId, tostring(payload)))
        comm.Connected = false
        comm.ShouldClose = true
    end

    this.ACK = function(payload)
        if payload then
            system.print("ACK", payload)
            --this.Communication.CurrentTransport.Sequence = payload
        end
    end

    this.DOCKR = function(payload)
        if payload then

        end
        return payload
    end

    return this
end

Transport = function(comm)
    local this = {}
    this.Nonce = {}
    this.Sequence = 0
    this.Communication = comm
    this.Name = "STOP"
    this.IsInitialized = false

    local createNonce = function()
        local added = false
        while not added do
            local nonce = math.random(1,99999999)
            if not this.Nonce[nonce] then
                this.Nonce[nonce] = true
                return nonce
            end
        end
    end

    this.Init = function(key)
        return "OK"
    end

    this.Begin = function()
        return "KO "..this.Communication.Id
    end

    this.Finalize = function()
        comm._OnHandshake()
        return this.Name
    end

    this.Encode = function(data)
        return data
    end

    this.Decode = function(data)
        return data
    end

    this.Read = function(data)
        data = this.Decode(data)
        local parts = split(data, " ")
        local nonce = tonumber(parts[#parts-1])
        local seq = tonumber(parts[#parts])
        parts[#parts] = ""
        parts[#parts-1] = ""
        if this.Nonce[nonce] == true or this.Sequence+1 ~= seq then
            error("Wrong sequence or nonce. Expected:"..this.Sequence+1)
            return
        end

        this.Nonce[nonce] = true
        this.Sequence = this.Sequence + 1

        return trim(table.concat(parts, " "))
    end

    this.Write = function(data)
        this.Sequence = this.Sequence + 1
        return this.Encode(string.format("%s %s %s", data, createNonce(), this.Sequence))
    end

    return this
end

Communication = function(myId, targetId, device, transports)
    local this = {}

    this.Id = tostring(myId)
    this.TargetId = tostring(targetId)
    this.Channel = "Wideband"
    this.RPC = RPC(this)
    this.Transports = transports
    this.CurrentTransport = this.Transports.STOP(this)
    this.Queue = {}
    this.Connected = false
    this.ShouldClose = false
    this.LastMessage = system.getTime()
    this.Timeout = 10
    this.Debug = false

    this._OnHandshake = function()
        if this.Debug then
            system.print(this.Id .. ","..this.TargetId.." completed handshake")
        end
        this.Connected = true
        this.OnHandshake()
    end

    this.OnHandshake = function()
    end

    this.SwitchTransport = function(name)
        local trans = this.Transports[name]
        if trans then
            if this.Debug then
                system.print(this.Id.." setting transport to "..name)
            end
            local oldSeq = this.CurrentTransport.Sequence
            local oldNonce = this.CurrentTransport.Nonce
            this.CurrentTransport = trans(this)
            this.CurrentTransport.Sequence = oldSeq
            this.CurrentTransport.Nonce = oldNonce
            return this.CurrentTransport
        end
        return false
    end

    this.Process = function()
        if #this.Queue == 0 and (system.getTime() - this.LastMessage) > this.Timeout then
            this.Close("Timeout")
            return false
        end
        local data = table.remove(this.Queue, 1)
        if device and data then
            device.send(this.TargetId, data)
            return true
        end
        return false
    end

    this.Send = function(pkgtype, ...)
        if not pkgtype then
            return
        end
        local payload = { ... }
        if #payload == 1 then
            payload = payload[1]
        else
            payload = trim(table.concat(payload, " "))
        end
        pkgtype = pkgtype:upper()
        local data = string.format("%s %s,%s|%s", pkgtype, this.Id, this.TargetId, this.CurrentTransport.Write(payload))

        if this.Debug then
            system.print(this.Id .. " sent:\t\t".. data)
        end

        table.insert(this.Queue, data)
        return data
    end

    this.Receive = function(str)
        if not str then
            return
        end
        str = str or ""

        if this.Debug then
            system.print(this.Id .. " recieved:\t".. str)
        end
        -- exclude HSK,HSKA,HSKB from decryption
        local parts = split(str, "|")
        if #parts == 2 then
            local header = split(parts[1], " ")
            local type = header[1]
            local payload = parts[2]
            local members = split(header[2], ",")
            local id,target = members[1],members[2]
            if tostring(target) ~= this.Id or tostring(id) ~= this.TargetId then
                error("Incorrect message id or target: "..str..". Expected id:"..this.Id.." and target:"..this.TargetId)
                return
            end
            
            local data = this.CurrentTransport.Read(payload)
            if data ~= nil then
                this.LastMessage = system.getTime()
                local rpc = this.RPC[type]
                if rpc then 
                    return rpc(data)
                else
                    error("Received invalid RPC: " .. type)
                end
            else
                -- something fucky going on
                return
            end
        else
            error("Received invalid message size: "..str)
            -- big fuckup
        end
    end

    this.Close = function(reason)
        if not reason then
            reason = "Closed"
        end
        this.Connected = false
        this.ShouldClose = true
        this.Send("DISC", reason)
    end

    return this
end

ConnectionManager = function(id, emitter, receiver)
    id = tostring(id)
    local this = {}
    this.Emitter = emitter
    this.Receiver = receiver

    this.Transports = {STOP = Transport}
    this.Connections = {}
    this.Channels = {"Wideband", tostring(id)}

    local function setChannels()
        receiver.setChannels(table.concat(this.Channels,","))
    end

    this.Connect = function(target, proto)
        target = tostring(target)
        -- TODO: unjank
        local connection = Communication(id, target, emitter, this.Transports)
        this.Connections[target] = connection
        setChannels()
        connection.Send("HSK", proto or "STOP")
        return connection
    end

    this.Disconnect = function(target)
        -- TODO: implement
        this.Connections[target].Close()
    end

    this.Process = function()
        for i,v in pairs(this.Connections) do
            local out = v.Process()
            if v.ShouldClose and #v.Queue == 0 then
                this.Connections[i] = nil
            end
            return out
        end
    end

    this.Receive = function(channel, data)
        local packet = split(data, "|")
        local headers = split(packet[1], " ")
        local members = split(headers[2], ",")
        local sender = members[1]
        local target = members[2]

        -- we're not the target
        if target ~= id then
            system.print("Wrong target ("..target..")")
            return
        end

        if not this.Connections[sender] then
            system.print(string.format("[%s] Connected.", sender))
            this.Connections[sender] = Communication(target, sender, emitter, this.Transports)
        end
        return this.Connections[sender].Receive(data)
    end

    setChannels()

    return this
end