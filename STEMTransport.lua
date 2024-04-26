--@class STEMTransport

local function stohex(s, ln, sep)
    local strf = string.format
    local byte = string.byte

	if #s == 0 then return "" end
	if not ln then
		return (s:gsub('.',
			function(c) return strf('%02x', byte(c)) end
			))
	end
	sep = sep or ""
	local t = {}
	for i = 1, #s - 1 do
		t[#t + 1] = strf("%02x%s", s:byte(i),
				(i % ln == 0) and '\n' or sep)
	end
	t[#t + 1] = strf("%02x", s:byte(#s))
	return concat(t)
end

local function hextos(hs, unsafe)
	local tonumber = tonumber
	if not unsafe then
		hs = string.gsub(hs, "%s+", "")
		if string.find(hs, '[^0-9A-Za-z]') or #hs % 2 ~= 0 then
			error("invalid hex string")
		end
	end
    local fmt = function(c)
        return string.char(tonumber(c, 16))
    end
	return hs:gsub('(%x%x)', fmt)
end

STEMTransport = function(comm)
    local this = Transport(comm)
    this.Name = "STEM"

    local DH = DHKE()
    local Public = nil
    local Shared = nil

    this.Init = function(key)
        if key then
            DH = DHKE(key)
            return key
        else
            local n = DH.GetRandomPrime()
            DH = DHKE(n)
            return n
        end
    end

    this.Begin = function(key)
        if key then
            Public = tonumber(key)
        end
        return DH.Public
    end

    this.Finalize = function()
        Shared = md5(tostring(DH.Validate(Public)))
        this.IsInitialized = true
        comm.OnHandshake()
    end

    local function getIV(seq)
        return string.format("%08d", seq)
        --return string.format("%08d", this.Sequence)
    end

    this.Encode = function(data)
        if Shared and this.IsInitialized then
            data = stohex(XTEA.Process(Shared, getIV(this.Sequence), data))
        end
        return data
    end

    this.Decode = function(data)
        if Shared and this.IsInitialized then
            data = XTEA.Process(Shared, getIV(this.Sequence+1), hextos(data))
            print("Decoded data: " .. data)
        end
        return data
    end

    return this
end