--@class StringExtensions

local stringmt = getmetatable("")

stringmt.__index["parseCommand"] = function(str)
    local out = {}
    local e = 0
    while true do
        local b = e+1
        b = str:find("%S",b)
        if b==nil then break end
        if str:sub(b,b)=="'" then
            e = str:find("'",b+1)
            b = b+1
        elseif str:sub(b,b)=='"' then
            e = str:find('"',b+1)
            b = b+1
        else
            e = str:find("%s",b+1)
        end
        if e==nil then e=#str+1 end
        local parsed = str:sub(b,e-1)
        if parsed then
            out[#out+1] = parsed:gsub("\\\"", "\"")
        end
    end
    return out
end
