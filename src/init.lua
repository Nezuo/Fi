--< Services >--
local DataStoreService = game:GetService("DataStoreService")

--< Modules >--
local Profile = require(script.Profile)

--< Variables >--
local Profiles = {}

--< Functions >--
local function OnClose()
    for _,profile in ipairs(Profiles) do
        profile:Save()
    end
end

--< Classes >--
local ProfileStore = {}
ProfileStore.__index = ProfileStore

function ProfileStore.new(name)
    local self = setmetatable({}, ProfileStore)
    
    self.DataStore = DataStoreService:GetDataStore(name)
    
    return self
end

function ProfileStore:LoadProfileAsync(key)
    local Data = self.DataStore:GetAsync(key) or {
        Coins = 0;
    }
    local NewProfile = Profile.new(self, key, Data)

    table.insert(Profiles, NewProfile)

    return NewProfile
end

--< Module >--
local Fi = {}

function Fi:GetProfileStore(name)
    return ProfileStore.new(name)
end

game:BindToClose(OnClose)

return Fi