--require FuelTanks.lua

SlotDetector = (function()
    local self = {}

    local function VirtualSlot(unitID)
        local self = {}
    
        if type(unitID) == "table" then
            --This is a real slot
            return unitID
        else
            self.ID = unitID
            local mt = {}
            mt.__index = function(t,k) return function(...) return _NQ_execute_method(t.ID, k, ...) end end

            setmetatable(self, mt)
        end
    
        return self
    end

    local function round(num, numDecimalPlaces)
        local mult = 10^(numDecimalPlaces or 0)
        return math.floor(num * mult + 0.5) / mult
    end

    local function identifyUnit(var, slots)
        if var["getElementClass"] then
            local id = var["getId"]()

            if id == nil then 
                if var["getConstructWorldPos"] then
                    --Def a core
                    slots.Core = var 
                end
                goto continue 
            end


            if slots.FoundIDs[id] ~= nil then goto continue end
            slots.FoundIDs[id] = true

            local class = var["getElementClass"]()

            if class == "SpaceFuelContainer" then
                local mass = round(var.getSelfMass(),2)
                local containerType = nil

                for k,fuelTank in pairs(FuelTanks) do
                    if mass==fuelTank.Mass then containerType = fuelTank break end
                end

                table.insert(slots.FuelTanks.Space[containerType.Class], var)
                goto continue
            end

            if class == "AtmoFuelContainer" then
                local mass = round(var.getSelfMass(),2)
                local containerType = nil

                for k,fuelTank in pairs(FuelTanks) do
                    if mass==fuelTank.Mass then containerType = fuelTank break end
                end

                table.insert(slots.FuelTanks.Atmo[containerType.Class], var)
                goto continue
            end

            if class == "RocketFuelContainer" then
                local mass = round(var.getSelfMass(),2)
                local containerType = nil

                for k,fuelTank in pairs(FuelTanks) do
                    if mass==fuelTank.Mass then containerType = fuelTank break end
                end

                table.insert(slots.FuelTanks.Rocket[containerType.Class], var)
                goto continue
            end

            if class == "ScreenUnit" then
                table.insert(slots.Screens, var)
            end


            if class == "DataBankUnit" then
                table.insert(slots.Databanks, var) 
                goto continue
            end

            if class == "TelemeterUnit" then
                table.insert(slots.Telemeters, var)
                goto continue
            end

            --Core unit
            if class == "Generic" then
                if var["getConstructWorldPos"] then
                    --Def a core
                    slots.Core = var 
                    goto continue
                end
            end

            if string.find(class, "SpaceEngine") then 
                table.insert(slots.Engines, var)
                goto continue
            end

            if string.find(class, "AtmosphericEngine") then 
                table.insert(slots.Engines, var)
                goto continue
            end

            if string.find(class, "RocketEngine") then 
                table.insert(slots.Engines, var)
                goto continue
            end

        end
        
        --if var["getRange"] then table.insert(slots.Radars, var) goto continue end
        --if var["setBaseAltitude"] then table.insert(slots.AntiGrav, var) goto continue end

        ::continue::

        return slots
    end

    function self.DetectSlotsInNamespace(container, slotContainer)
        local slots = {FoundIDs={}, Engines={}, FuelTanks={Atmo={XS={},S={},M={},L={}}, Rocket={XS={},S={},M={},L={}}, Space={S={},M={},L={}}}, Core=nil, Screens={}, Telemeters={}, Radars={}, AntiGrav={}, Databanks={}}
        if slotContainer ~= nil then slots = slotContainer end

        for slotName,var in pairs(container) do
            slots = identifyUnit(var, slots)
        end
        return slots
    end
    function self.DetectSlotsFromList(list, slotContainer)
        local slots = {FoundIDs={}, Engines={}, FuelTanks={Atmo={XS={},S={},M={},L={}}, Rocket={XS={},S={},M={},L={}}, Space={S={},M={},L={}}}, Core=nil, Screens={}, Telemeters={}, Radars={}, AntiGrav={}, Databanks={}}
        if slotContainer ~= nil then slots = slotContainer end

        for k,v in pairs(list) do
            local slot = VirtualSlot(v)
            slots = identifyUnit(slot, slots)
        end
        return slots
    end
    
    return self
end)()