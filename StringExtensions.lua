--@class StringExtensions

local stringmt = getmetatable("")

stringmt.__index["parseCommand"] = function(str)
    local out = {}
    local tail = 0
    local rollback = 0
    local special = {';','|','>>','>','<','&&','&','||'}
    local specialConcat = table.concat(special, "")
    while true do
        local start = tail+1-rollback
        rollback = 0
        start = str:find("%S",start)
        if start==nil then break end
        if str:sub(start,start)=="'" then
            tail = str:find("'",start+1)
            start = start+1
        elseif str:sub(start,start)=='"' then
            tail = str:find('"',start+1)
            start = start+1
        else
            local isSpecial = false
            for i=1,#special do
                local chr = special[i]
                local first = str:sub(start,start+(#chr-1))
                if chr == first then
                    tail = start+#chr
                    start = start
                    rollback = 1
                    isSpecial = true
                    break
                end
            end
            if not isSpecial then
                ---check if contains special
                local sTail = str:find("["..specialConcat.."]",start+1)
                local nTail = str:find("%s",start+1)
                if sTail then
                    if sTail <= nTail then
                        tail = sTail
                        rollback = 1
                    else
                        tail = nTail
                    end
                else
                    tail = nTail
                end
            end
        end
        if tail==nil then tail=#str+1 end
        local parsed = str:sub(start,tail-1)
        if parsed then
            out[#out+1] = parsed:gsub("\\\"", "\"")
        end
    end
    return out
end
