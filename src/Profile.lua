--< Module >--
local Profile = {}

function Profile.new(profileStore, key, data)
    local self = {}
    
    self.ProfileStore = profileStore
    self.ActiveSession = data.ActiveSession
    self.Data = data.Data
    self.Key = key
    self.LoadedTimestamp = nil

    return self
end

return Profile