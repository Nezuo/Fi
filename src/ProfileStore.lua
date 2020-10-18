--< Modules >--
local Asink = require(script.Parent.Asink)
local Constants = require(script.Parent.Constants)
local Profile = require(script.Parent.Profile)

--< Variables >--
local LoadingLocked = false -- TODO: Add tests for this.

--< Functions >--
local function OnClose()
    LoadingLocked = true
end

local function LoadProfileData(dataStore, key, transform)
    return pcall(function()
        return dataStore:UpdateAsync(key, transform)
    end)
end

local function LoadProfile(profileStore, key)
    local Future, Resolve = Asink.Future.new()

    Asink.Runtime.exec(function()
        local Start = os.clock()
        
        repeat
            local Success, Response = LoadProfileData(profileStore.DataStore, key, function(data)
                if LoadingLocked then
                    return data
                end

                data = data or {
                    ActiveSession = nil;
                    Data = {};
                }

                if data.ActiveSession == nil then
                    data.ActiveSession = game.JobId
                end

                return data
            end)

            if not Success then
                warn(Response)
            end

            if LoadingLocked then
                break
            end

            if Success and Response.ActiveSession == game.JobId then
                Resolve(Asink.Result.ok(Profile.new(profileStore, key, Response)))

                break
            end

            if os.clock() - Start < Constants.TIME_BEFORE_FORCE_STEAL and not LoadingLocked then
                wait(Constants.LOAD_RETRY_DELAY)
            end
        until os.clock() - Start > Constants.TIME_BEFORE_FORCE_STEAL or LoadingLocked

        if LoadingLocked then
            Resolve(Asink.Result.error("Profile `" .. key .. "` cannot be loading because the server is shutting down."))

            return
        end

        -- Steal the profile and session lock it.
        local Success, Response = LoadProfileData(profileStore.DataStore, key, function(data)
            data.ActiveSession = game.JobId

            return data
        end)

        if Success then
            Resolve(Asink.Result.ok(Profile.new(profileStore, key, Response)))
        else
            Resolve(Asink.Result.error(Response))
        end
    end)

    return Future
end

--< Module >--
local ProfileStore = {}
ProfileStore.UseMockDataStore = false
ProfileStore.__index = ProfileStore

function ProfileStore.new(name)
    local self = setmetatable({}, ProfileStore)
    
    local DataStoreService = ProfileStore.UseMockDataStore and require(script.Parent.MockDataStoreService) or game:GetService("DataStoreService")

    self.Name = name
    self.DataStore = DataStoreService:GetDataStore(name)
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

    if LoadingLocked then
        error("Profile `" .. key .. "` cannot be loaded because the server is shutting down.")
    end

    local Future = LoadProfile(self, key)

    self.LoadJobs[key] = Future

    Future:map(function(result)
        local Success, Response = result:unpack()

        if Success then
            self.Profiles[key] = Response
        else
            warn(Response)
        end

        self.LoadJobs[key] = nil
    end)

    return Future
end

--< Initialize >--
game:BindToClose(OnClose)

return ProfileStore