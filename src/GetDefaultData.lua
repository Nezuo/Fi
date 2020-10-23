--< Module >--
local function GetDefaultData(activeSession)
    return {
        ActiveSession = activeSession;
        Data = {};
        Metadata = {
            LastUpdate = os.time();
        };
    }
end

return GetDefaultData