--< Module >--
local Profile = {}
Profile.__index = Profile

function Profile.new(profileStore, key, data)
    local self = setmetatable({}, Profile)
    
    self.ProfileStore = profileStore
    self.Data = data
    self.Key = key
    
    self.IsSaving = false

    return self
end

function Profile:Save()
    if self.IsSaving then
        return
    end

    self.IsSaving = true

    self.ProfileStore.DataStore:UpdateAsync(self.Key, function()
        return self.Data
    end)

    self.IsSaving = false
end

return Profile