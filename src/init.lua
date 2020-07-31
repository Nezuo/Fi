--< Services >--
local DataStoreService = game:GetService("DataStoreService")

--< Modules >--
local Asink = require(script.Asink)
local Profile = require(script.Profile)

--< Variables >--
local ProfileStores = {}
local ProfileSaveFutures = {}

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

local function LoadProfile(profileStore, key)
    local Future, Resolve = Asink.Future.new()

    Asink.Runtime.exec(function()
        if ProfileStores[profileStore.Name][key] then
            Resolve(Asink.Result.error("Profile of ProfileStore `" .. profileStore.Name .. "` with key `" .. key .. "` has already been loaded in this session."))
        end

        local Success, Response = pcall(function()
            return profileStore.DataStore:UpdateAsync(key, function(data)
                return data
            end)
        end)

        if Success then
            local Data = Response or {
                Coins = 0;
            }

            local NewProfile = Profile.new(profileStore, key, Data)
            ProfileStores[profileStore.Name][key] = NewProfile

            Resolve(Asink.Result.ok(NewProfile))
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
    self.ProfileLoadFutures = {}

    return self
end

function ProfileStore:LoadProfileAsync(key)
    -- EDGE CASE: Prevents an error when a player rejoins the same server before their data is fully loaded
    local ExistingFuture = self.ProfileLoadFutures[key]
    if ExistingFuture then
        return ExistingFuture
    end

    local Future = LoadProfile(self, key)
    Future:map(function()
        self.ProfileLoadFutures[key] = nil
    end)

    self.ProfileLoadFutures[key] = Future

    return Future
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
    if ProfileSaveFutures[profile] then
        return
    end

    local Future = SaveProfile(profile)
    Future:map(function(result)
        local Success, Response = result:unpack()

        if not Success then
            warn(Response)
        end

        ProfileSaveFutures[profile] = nil
    end)

    ProfileSaveFutures[profile] = Future

    return Future
end

game:BindToClose(function()
    local Futures = {}

    for _,profileStore in pairs(ProfileStores) do
        for _,profile in pairs(profileStore) do
            if ProfileSaveFutures[profile] then
                table.insert(Futures, ProfileSaveFutures[profile])
            end

            local Future = Fi:SaveProfile(profile)
    
            table.insert(Futures, Future)
        end
    end

    Asink.Future.all(Futures):await()
end)

return Fi