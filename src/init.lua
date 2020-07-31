--< Services >--
local DataStoreService = game:GetService("DataStoreService")

--< Modules >--
local Asink = require(script.Asink)
local Profile = require(script.Profile)

--< Variables >--
local ProfileStores = {}
local ProfileFutures = {}

--< Functions >--
local function SaveProfile(profile)
    local Future, Resolve = Asink.Future.new()

    Asink.Runtime.exec(function()
        local Success, Response = pcall(function()
            return profile.ProfileStore.DataStore:UpdateAsync(profile.Key, function()
                return profile.Data
            end)
        end)

        if Success then
            Resolve(Asink.Result.ok(Response))
        else
            Resolve(Asink.Result.error(Response))
        end
    end)

    return Future
end

--< Classes >--
local ProfileStore = {}
ProfileStore.__index = ProfileStore

function ProfileStore.new(name)
    local self = setmetatable({}, ProfileStore)
    
    self.Name = name
    self.DataStore = DataStoreService:GetDataStore(name)
    
    return self
end

function ProfileStore:LoadProfileAsync(key)
    if ProfileStores[self.Name][key] then
        error("Profile of ProfileStore `" .. self.Name .. "` with key `" .. key .. "` has already been loaded in this session.")
    end

    local Data = self.DataStore:GetAsync(key) or {
        Coins = 0;
    }

    local NewProfile = Profile.new(self, key, Data)
    ProfileStores[self.Name][key] = NewProfile

    return NewProfile
end

--< Module >--
local Fi = {}

function Fi:GetProfileStore(name)
    if ProfileStores[name] then
        error("ProfileStore `" .. name .. "` has already been loaded in this session.")
    end

    ProfileStores[name] = {}

    return ProfileStore.new(name)
end

function Fi:SaveProfile(profile)
    if ProfileFutures[profile] then
        return
    end

    local Future = SaveProfile(profile)
    Future:map(function(result)
        local Success, Response = result:unpack()

        if not Success then
            warn(Response)
        end

        ProfileFutures[profile] = nil
    end)

    ProfileFutures[profile] = Future

    return Future
end

game:BindToClose(function()
    local Futures = {}

    for _,profileStore in pairs(ProfileStores) do
        for _,profile in pairs(profileStore) do
            if ProfileFutures[profile] then
                table.insert(Futures, ProfileFutures[profile])
            end
    
            local Future = Fi:SaveProfile(profile)
    
            table.insert(Futures, Future)
        end
    end

    Asink.Future.all(Futures):await()
end)

return Fi