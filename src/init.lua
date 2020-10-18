--< Modules >--
local Asink = require(script.Asink)
local Futures = require(script.Futures)
local ProfileStore = require(script.ProfileStore)

--< Variables >--
local Fi = {
    ProfileStores = {};
    SaveJobs = {};
    ReleaseJobs = {};
}

function Fi:GetProfileStore(name)
    if #name == 0 then
        error("ProfileStore name cannot be an empty string.")
    end

    if #name > 50 then
        error("ProfileStore name cannot be more than 50 characters." )
    end

    if self.ProfileStores[name] ~= nil then
        error("ProfileStore `" .. name .. "` has already been loaded in this session.")
    end

    self.ProfileStores[name] = ProfileStore.new(name)

    return self.ProfileStores[name]
end

function Fi:ReleaseProfile(profile)
    if self.ReleaseJobs[profile] ~= nil then
        return self.ReleaseJobs[profile]
    end

    local Profiles = self.ProfileStores[profile.ProfileStore.Name].Profiles

    if Profiles[profile.Key] == nil then
        error("Profile `" .. profile.Key .. "` in ProfileStore `" .. profile.ProfileStore.Name .. "` has already been released.")
    end

    local Future = Futures.ReleaseProfile(Profiles, profile)
    Future:map(function(result)
        local Success, Response = result:unpack()

        if not Success then
            warn(Response)
        end

        self.ReleaseJobs[profile] = nil
    end)

    self.ReleaseJobs[profile] = Future

    return Future
end

function Fi:SaveProfile(profile)
    if self.SaveJobs[profile] ~= nil then
        return self.SaveJobs[profile]
    end

    local Future = Futures.SaveProfile(profile, false)
    Future:map(function(result)
        local Success, Response = result:unpack()

        if not Success then
            warn(Response)
        end

        self.SaveJobs[profile] = nil
    end)

    self.SaveJobs[profile] = Future

    return Future
end

--< Functions >--
local function OnClose()
    local CloseFutures = {}
    for _,profileStore in pairs(Fi.ProfileStores) do
        for _,profile in pairs(profileStore.Profiles) do
            table.insert(CloseFutures, Futures.ReleaseProfile(Fi, profile))
        end
    end

    Asink.Future.all(CloseFutures):await()
end

--< Initialize >--
game:BindToClose(OnClose) -- TODO: Only do this if not using a mock data store!

--< Module >--
return Fi