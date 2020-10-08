--< Module >--
local Profile = {}
Profile.__index = Profile

function Profile.new(profileStore, key, data)
    local self = setmetatable({}, Profile)
    
    self.ProfileStore = profileStore
    self.ActiveSession = data.ActiveSession
    self.Data = data.Data
    self.Key = key

    return self
end

return Profile