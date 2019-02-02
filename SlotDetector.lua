function SlotDetector(container)
    if not container then container = _G end
    local slots = {Engines={}, SpaceFuelTanks={}, AtmoFuelTanks={}, Core=nil, Screens={}, Telemeters={}, Radars={}, AntiGrav={}}
    for slotName,var in pairs(container) do
        if type(var) ~= "table" then goto continue end
        if not var["getId"] then goto continue end
        if var["getConstructWorldPos"] then slots.Core = var goto continue end
        if var["getMaxThrust"] then table.insert(slots.Engines, var) goto continue end
        if var["setRawHTML"] then table.insert(slots.Screens, var) goto continue end
        if var["getMaxDistance"] then table.insert(slots.Telemeters, var) goto continue end
        if var["getRange"] then table.insert(slots.Radars, var) goto continue end
        if var["setBaseAltitude"] then table.insert(slots.AntiGrav, var) goto continue end
        if var["getSelfMass"] then
            --Is Fuel/Container
            local mass = var["getSelfMass"]
            if mass == 8.87 or mass == 38.34 or mass == 308.56 or mass == 2453.74 then table.insert(slots.AtmoFuelTanks, var) goto continue end
            if mass == 38.08 or mass == 304.61 or mass == 2436.87 then table.insert(slots.SpaceFuelTanks, var) goto continue end
            goto continue
        end

        ::continue::
    end
    return slots
end

function ScopePromoter(source, dest)
    for slotName,var in pairs(source) do
        if type(var) == "function" then goto continue end
        if not var["getId"] then goto continue end
        dest[slotName]=var
        ::continue::
    end
end