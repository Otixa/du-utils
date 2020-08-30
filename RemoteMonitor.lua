RemoteMonitor = (function(db)

    for k,v in pairs(_G) do
        if string.find(k, "Unit_") then databank.setStringValue(k,k) end
    end

end)(databank)