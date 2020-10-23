--< Module >--
local Profile = {}

function Profile.new(profileStore, key, data, stolenMessage)
    local self = {}
    
    self.ProfileStore = profileStore
    self.Metadata = data.Metadata
    self.ActiveSession = data.ActiveSession
    self.Data = data.Data
    self.Key = key
    self.LoadedTimestamp = nil
    self.StolenMessage = stolenMessage

    return self
end

return Profile