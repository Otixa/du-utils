--require FuelTanks.lua

RemoteMonitor = (function(i, db, s)

    local identifier = i
    local databank = db
    local slots = s
    local this = {}
    local data = {}

    function this.Update()

        --Monitor telemeters
        for i=1,#s.Telemeters,1 do
            local distance = slots[i].getDistance()
            db.setFlotValue(identifier..".telemeter.distance."..i, distance)
        end

        --Monitor fuel tanks
        for tankType,tanks in s.SpaceFuelTanks do
            
        end
        for i=1,#s.SpaceFuelTanks,1 do
            local mass = slots[i].getItemMass()
            db.setFlotValue(identifier..".spacefueltank.mass."..i, mass)
        end
        --Monitor fuel tanks
        for i=1,#s.AtmoFuelTanks,1 do
            local mass = slots[i].getItemMass()
            db.setFlotValue(identifier..".atmofueltank.mass."..i, mass)
        end

    end



    return this

end)