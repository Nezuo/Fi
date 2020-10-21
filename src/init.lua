--< Services >--
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

--< Modules >--
local Asink = require(script.Asink)
local AutoSave = require(script.AutoSave)
local Constants = require(script.Constants)
local Futures = require(script.Futures)
local ProfileStore = require(script.ProfileStore)
local Queue = require(script.Queue)
local State = require(script.State)

--< Variables >--
local UsingMockData = Constants.USE_MOCK_DATA_STORE

--< Module >--
local Fi = {
    AutoSaveQueue = Queue.new();
    ProfileStores = {};
    SaveJobs = {};
    ReleaseJobs = {};
}

function Fi:GetProfileStore(name)
    if #name == 0 then
        error("ProfileStore name cannot be an empty string.")
    elseif #name > 50 then
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

    self.ReleaseJobs[profile] = Future

    Future:map(function(result)
        local Success, Response = result:unpack()

        if not Success then
            warn(Response)
        end
        
        self.AutoSaveQueue:Remove(profile)

        self.ReleaseJobs[profile] = nil
    end)

    return Future
end

function Fi:SaveProfile(profile)
    if self.SaveJobs[profile] ~= nil then
        return self.SaveJobs[profile]
    end

    local Future = Futures.SaveProfile(profile, false)

    self.SaveJobs[profile] = Future
    
    Future:map(function(result)
        local Success, Response = result:unpack()

        if not Success then
            warn(Response)
        end

        self.SaveJobs[profile] = nil
    end)

    return Future
end

--< Functions >--
local function OnClose()
    State.LoadingLocked = true

    if not UsingMockData then
        local CloseFutures = {}
        for _,profileStore in pairs(Fi.ProfileStores) do
            for _,profile in pairs(profileStore.Profiles) do
                table.insert(CloseFutures, Futures.ReleaseProfile(Fi, profile))
            end
        end
    
        Asink.Future.all(CloseFutures):await()
    end
end

--< Initialize >--
if not UsingMockData then
    if game.GameId == 0 then
        -- In a local place file.
        UsingMockData = true
    elseif RunService:IsStudio() then
        local Status, Message = pcall(function()
            -- This will error if Studio does not have API Access.
            DataStoreService:GetDataStore("__TEST"):SetAsync("__TEST", "__TEST_" .. os.time())
        end)

        if not Status and string.find(Message, "403", 1, true) then
            UsingMockData = true
        end
    end
end

State.UseMockDataStore = UsingMockData

AutoSave:Start(Fi)

game:BindToClose(OnClose)

--< Module >--
return Fi