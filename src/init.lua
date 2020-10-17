--< Modules >--
local Asink = require(script.Asink)
local ProfileStore = require(script.ProfileStore)

--< Variables >--
local ProfileStores = {}
local SaveJobs = {}
local ReleaseJobs = {}

--< Functions >--
local function SaveProfile(profile, release)
    local Future, Resolve = Asink.Future.new()

    Asink.Runtime.exec(function()
        local Success, Response = pcall(function()
            return profile.ProfileStore.DataStore:UpdateAsync(profile.Key, function()
                return {
                    ActiveSession = release and nil and profile.ActiveSession;
                    Data = profile.Data;
                }
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

local function Release(profile)
    if ReleaseJobs[profile] then
        return ReleaseJobs[profile]
    end

    local Profiles = ProfileStores[profile.ProfileStore.Name]

    if Profiles[profile.Key] then
        error("Profile `" .. profile.Key .. "` in ProfileStore `" .. profile.ProfileStore.Name .. "` has already been released.")
    end

    local Future = SaveProfile(profile, true)
    Future:map(function(result)
        local Success, Response = result:unpack()

        if not Success then
            warn(Response)
        end

        Profiles[profile.Key] = nil
        ReleaseJobs[profile] = nil
    end)

    ReleaseJobs[profile] = Future

    return Future
end

local function OnClose()
    local Futures = {}
    for _,profileStore in pairs(ProfileStores) do
        for _,profile in pairs(profileStore.Profiles) do
            table.insert(Futures, Release(profile))
        end
    end

    Asink.Future.all(Futures):await()
end

--< Module >--
local Fi = {}

function Fi:GetProfileStore(name)
    if #name == 0 then
        error("ProfileStore name cannot be an empty string.")
    end

    if #name > 50 then
        error("ProfileStore name cannot be more than 50 characters." )
    end

    if ProfileStores[name] then
        error("ProfileStore `" .. name .. "` has already been loaded in this session.")
    end

    ProfileStores[name] = ProfileStore.new(name)

    return ProfileStores[name]
end

function Fi:SaveProfile(profile)
    if SaveJobs[profile] then
        return SaveJobs[profile]
    end

    local Future = SaveProfile(profile)
    Future:map(function(result)
        local Success, Response = result:unpack()

        if not Success then
            warn(Response)
        end

        SaveJobs[profile] = nil
    end)

    SaveJobs[profile] = Future

    return Future
end

function Fi:ReleaseProfile(profile)
    return Release(profile)
end

--< Initialize >--
game:BindToClose(OnClose) -- TODO: Only do this if not using a mock data store!

return Fi