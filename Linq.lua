--@class Linq

---Create an instance of the Linq class for the given table
---@class Linq
---@param collection table A Lua table to perform operations on.
---@return Linq
Linq = function(collection)
    ---@class Linq
    local this = {}


    ---The raw value of the collection.
    ---@type table
    this.Value = collection

    if type(collection) ~= "table" then
        collection = {collection}
    end

    local function getTrueSize()
        local n = 0
        for _ in pairs(collection) do 
          n = n + 1 
        end
        return n   
    end

    local function dump(tbl, indent)
        if not indent then indent = 0 end
        local prefix = ""
        for i=1,indent do
            prefix = prefix .. "  "
        end
        for k, v in pairs(tbl) do
            if type(v) ~= "table" or v == nil then
                system.print(prefix.."["..tostring(k).."] = "..tostring(v))
            else
                system.print(prefix.."["..tostring(k).."] = {")
                dump(v, indent+1)
                system.print("}")
            end
        end
    end

    ---Projects each element of a sequence into a new form.
    ---@param predicate string|function
    ---@return Linq Transformed A collection of the transformed elements.
    function this.Select(predicate)
        local result = {}
        local i = 1
        if type(predicate) == "function" then
            for k, v in ipairs(collection) do
                result[i] = predicate(v, k)
                i = i + 1
            end
        elseif type(predicate) == "string" then
            for k, v in ipairs(collection) do
                if predicate == "" then
                    result[i] = v
                else
                    result[i] = v[predicate]
                end
                i = i + 1
            end
        else
            error("Invalid predicate type.")
        end

        return Linq(result)
    end

    ---Filters a sequence of values based on a predicate.
    ---@param predicate function
    ---@return Linq Matches A collection of elements matching the predicate.
    this.Where = function(predicate)
        local result = {}
        local i = 1

        if type(predicate) == "function" then
            for k, v in ipairs(collection) do
                if predicate(v, k) == true then
                    result[i] = v
                    i = i + 1
                end
            end
        else
            error("Invalid predicate type.")
        end

        return Linq(result)
    end

    ---Returns the first element in a sequence that satisfies a specified condition.
    ---@param predicate function|nil
    ---@return any Match Matching element.
    this.First = function(predicate)
        if type(predicate) == "function" then
            for k, v in ipairs(collection) do
                if predicate(v, k) == true then
                    return v
                end
            end
        elseif predicate == nil then
            -- Check if there's a 1 index
            if collection[1] ~= nil then
                return collection[1]
            else
                local k,v = pairs(collection)
                return v
            end

        else
            error("Invalid predicate type.")
        end
    end

    ---Returns the last element in a sequence that satisfies a specified condition.
    ---@param predicate function|nil
    ---@return any Match Matching element.
    this.Last = function(predicate)
        if type(predicate) == "function" then
            local last = nil
            for k, v in ipairs(collection) do
                if predicate(v, k) == true then
                    last = v
                end
            end
            return last
        elseif predicate == nil then
            if collection[#collection] ~= nil then
                return collection[#collection]
            else
                local last = nil
                for k, v in pairs(collection) do
                    last = v
                end
                return last
            end
        else
            error("Invalid predicate type.")
        end
    end

    ---Determines whether any element of a sequence exists or satisfies a condition.
    ---@param predicate function|nil
    ---@return boolean Result Result indicating whether any elements match.
    this.Any = function(predicate)
        if type(predicate) == "function" then
            for k, v in ipairs(collection) do
                if predicate(v, k) == true then
                    return true
                end
            end
        elseif predicate == nil then
            return getTrueSize() ~= 0
        else
            error("Invalid predicate type.")
        end
        return false
    end

    ---Determines whether all elements of a sequence satisfy a condition.
    ---@param predicate function
    ---@return boolean Result Result indicating whether all elements match.
    this.All = function(predicate)
        if type(predicate) == "function" then
            for k, v in pairs(collection) do
                if predicate(v, k) == false then
                    return false
                end
            end
        else
            error("Invalid predicate type.")
        end
        return true
    end

    ---Groups the elements of a sequence according to a specified key selector function and creates a result value from each group and its key. Key values are compared by using a specified comparer, and the elements of each group are projected by using a specified function.
    ---@param predicate function
    ---@return Linq Grouped Table indexed by the provided predicate
    this.GroupBy = function(predicate)
        local result = {}

        if type(predicate) == "function" then
            for k, v in pairs(collection) do
                local res = predicate(v, k)
                if not result[res] then
                    result[res] = {}
                end
                table.insert(result[res], v)
            end
        elseif type(predicate) == "string" then
            for k, v in pairs(collection) do
                if v[predicate] then
                    local res = v[predicate]
                    if not result[res] then
                        result[res] = {}
                    end
                    table.insert(result[res], v)
                end
            end
        else
            error("Invalid predicate type.")
        end
        return Linq(result)
    end

    -- Warning: This modifies original collection. Might be worth making a copy?
    ---Sorts the elements of a sequence in ascending order.
    ---@param predicate function|string Function which takes in a and b and performs a comparison. If a string is provided, it performs a simple sort with the predicate string used as a key.
    ---@return Linq Ordered The ordered table
    this.OrderBy = function(predicate)
        if type(predicate) == "function" then
            table.sort(collection, predicate)
            return Linq(collection)
        elseif type(predicate) == "string" then
            table.sort(collection, function(a,b) return a[predicate] < b[predicate] end)
            return Linq(collection)
        else
            error("Invalid predicate type.")
        end
    end

    -- Warning: This modifies original collection. Might be worth making a copy?
    ---Sorts the elements of a sequence in descending order.
    ---@param predicate function|string Function which takes in a and b and performs a comparison. If a string is provided, it performs a simple sort with the predicate string used as a key.
    ---@return Linq Ordered The ordered table
    this.OrderByDescending = function(predicate)
        if type(predicate) == "function" then
            table.sort(collection, predicate)
            return Linq(collection)
        elseif type(predicate) == "string" then
            table.sort(collection, function(a,b) return a[predicate] > b[predicate] end)
            return Linq(collection)
        else
            error("Invalid predicate type.")
        end
    end

    ---Returns the minimum value in a sequence of values.
    ---@param predicate function|string|nil A function or string which selects the appropriate datum from each element.
    ---@return any Smallest The element with the smallest value according to the predicate.
    this.Min = function(predicate)
        local result = nil

        if type(predicate) == "string" and predicate ~= "" then
            local val = predicate
            predicate = function(v) return v[val] end
        end

        if predicate == nil or predicate == "" then
            predicate = function(v) return v end
        end

        if type(predicate) == "function" then
            for k, v in pairs(collection) do
                if result == nil then
                    result = v
                end
                local res = predicate(v)
                if res < predicate(result) then
                    result = v
                end
            end
        else
            error("Invalid predicate type.")
        end

        return result
    end

    ---Returns the maximum value in a sequence of values.
    ---@param predicate function|string|nil A function or string which selects the appropriate datum from each element.
    ---@return any Smallest The element with the largest value according to the predicate.
    this.Max = function(predicate)
        local result = nil

        if type(predicate) == "string" and predicate ~= "" then
            local val = predicate
            predicate = function(v) return v[val] end
        end

        if predicate == nil or predicate == "" then
            predicate = function(v) return v end
        end

        if type(predicate) == "function" then
            for k, v in pairs(collection) do
                if result == nil then
                    result = v
                end
                local res = predicate(v, k)
                if res > predicate(result) then
                    result = v
                end
            end
        else
            error("Invalid predicate type.")
        end

        return result
    end

    ---Computes the sum of a sequence of numeric values.
    ---@param predicate function|string|nil A function or string which selects the appropriate datum from each element.
    ---@return number Sum The sum of the element values.
    this.Sum = function(predicate)
        local result = 0

        if type(predicate) == "string" and predicate ~= "" then
            local val = predicate
            predicate = function(v) return v[val] end
        end

        if predicate == nil or predicate == "" then
            predicate = function(v) return v end
        end

        if type(predicate) == "function" then
            for k, v in pairs(collection) do
                local res = predicate(v)
                result = result + res
            end
        else
            error("Invalid predicate type.")
        end

        return result
    end

    ---Computes the average value of a sequence of numeric values.
    ---@param predicate function|string|nil A function or string which selects the appropriate datum from each element.
    ---@return number Average The average of the element values.
    this.Average = function(predicate)
        local result = {}
        local index = 1

        if type(predicate) == "string" and predicate ~= "" then
            local val = predicate
            predicate = function(v) return v[val] end
        end

        if predicate == nil or predicate == "" then
            predicate = function(v) return v end
        end

        if type(predicate) == "function" then
            for k, v in pairs(collection) do
                local res = predicate(v)
                result[index] = res
                index = index + 1
            end
        else
            error("Invalid predicate type.")
        end

        return Linq(result).Sum() / #result
    end

    ---Returns the values of the collection as a numerically indexed table.
    ---@return table Values The values of the collection.
    this.Values = function()
        return this.ToArray()
    end

    ---Returns the keys of the collection as a numerically indexed table.
    ---@return table Keys The keys of the collection.
    this.Keys = function()
        local result = {}
        local index = 1
        for k, v in pairs(collection) do
            result[index] = k
            index = index + 1
        end
        return result
    end

    ---Returns distinct elements from a sequence.
    ---@param predicate function|string|nil A function or string which selects the appropriate datum from each element.
    ---@return table Distinct The unique values of the collection as accessed by the predicate.
    this.Distinct = function(predicate)
        local result = {}

        if type(predicate) == "string" and predicate ~= "" then
            local val = predicate
            predicate = function(v) return v[val] end
        end

        if predicate == nil or predicate == "" then
            predicate = function(v) return v end
        end

        if type(predicate) == "function" then
            for k, v in pairs(collection) do
                local p = predicate(v)
                result[p] = v
            end
        else
            error("Invalid predicate type.")
        end

        return Linq(Linq(result).Keys())
    end

    ---Returns the number of elements in a sequence.
    ---@return number Count The number of elements in the sequence.
    this.Count = function()
        return getTrueSize()
    end

    ---Returns the values of the collection as a numerically indexed table.
    ---@return table Values The values of the collection.
    this.ToArray = function()
        local result = {}
        local index = 1
        for k, v in pairs(collection) do
            result[index] = v
            index = index + 1
        end
        return result
    end

    ---Outputs the collection to system console recursively.
    this.Dump = function()
        dump(collection)
    end

    setmetatable(this, { __call = function() return this.Value end })
    return this
end