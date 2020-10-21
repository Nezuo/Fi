--< Services >--
local DataStoreService = game:GetService("DataStoreService")

--< Modules >--
local MockDataStoreService = require(script.Parent.MockDataStoreService)
local Futures = require(script.Parent.Futures)
local State = require(script.Parent.State)
local AutoSave = require(script.Parent.AutoSave)

--< Module >--
local ProfileStore = {}
ProfileStore.__index = ProfileStore

function ProfileStore.new(name)
    local self = setmetatable({}, ProfileStore)
    
    local DataService = State.UseMockDataStore and MockDataStoreService or DataStoreService

    self.Name = name
    self.DataStore = DataService:GetDataStore(name)
    self.Profiles = {}
    self.LoadJobs = {}

    return self
end

function ProfileStore:LoadProfile(key)
    -- EDGE CASE: Prevents an error when a player rejoins the same server before their data is fully loaded
    if self.LoadJobs[key] ~= nil then
        return self.LoadJobs[key]
    end

    if #key > 50 then
        error("Profile key cannot be more than 50 characters.")
    end

    if self.Profiles[key] ~= nil then
        error("Profile `" .. key .. "` has already been loaded in ProfileStore `" .. self.Name .. "` in this session.")
    end

    if State.LoadingLocked then
        error("Profile `" .. key .. "` cannot be loaded because the server is shutting down.")
    end

    local Future = Futures.LoadProfile(self, key)

    self.LoadJobs[key] = Future

    Future:map(function(result)
        local Success, Response = result:unpack()

        if Success then
            Response.LoadedTimestamp = os.clock()
            
            self.Profiles[key] = Response

            AutoSave:AddProfileToQueue(Response)
        else
            warn(Response)
        end

        self.LoadJobs[key] = nil
    end)
    
    return Future
end

return ProfileStore