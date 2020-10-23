--< Services >--
local RunService = game:GetService("RunService")

--< Modules >--
local Asink = require(script.Parent.Asink)
local State = require(script.Parent.State)
local Constants = require(script.Parent.Constants)
local Profile = require(script.Parent.Profile)
local GetDefaultData = require(script.Parent.GetDefaultData)

--< Functions >--
local function Wait(dt)
	dt = math.max(0, dt)
	local left = dt

	while left > 0 do
		left = left - RunService.Heartbeat:Wait()
	end

	return dt - left
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
            local StolenMessage = nil

            local Success, Response = LoadProfileData(profileStore.DataStore, key, function(data)
                if State.LoadingLocked then
                    return data
                end

                data = data or GetDefaultData()

                if data.ActiveSession == nil  then
                    data.ActiveSession = game.JobId
                    data.Metadata.LastUpdate = os.time()
                end

                if data.ActiveSession ~= game.JobId and os.time() - data.Metadata.LastUpdate >= Constants.ASSUME_DEAD_SESSION_LOCK then
                    StolenMessage = "DeadSession"

                    data.ActiveSession = game.JobId
                    data.Metadata.LastUpdate = os.time()
                end

                return data
            end)

            if not Success then
                warn(Response)
            end

            if State.LoadingLocked then
                break
            end

            if Success and Response.ActiveSession == game.JobId then
                Resolve(Asink.Result.ok(Profile.new(profileStore, key, Response, StolenMessage)))

                return
            end

            if os.clock() - Start < Constants.TIME_BEFORE_FORCE_STEAL and not State.LoadingLocked then
                Wait(Constants.LOAD_RETRY_DELAY)
            end
        until os.clock() - Start > Constants.TIME_BEFORE_FORCE_STEAL or State.LoadingLocked

        if State.LoadingLocked then
            Resolve(Asink.Result.error("Profile `" .. key .. "` cannot be loading because the server is shutting down."))

            return
        end

        -- Steal the profile and session lock it.
        local Success, Response = LoadProfileData(profileStore.DataStore, key, function(data)
            data.ActiveSession = game.JobId

            return data
        end)

        if Success then
            Resolve(Asink.Result.ok(Profile.new(profileStore, key, Response, "ForceSteal")))
        else
            Resolve(Asink.Result.error(Response))
        end
    end)

    return Future
end

local function SaveProfile(profile, release)
    local Future, Resolve = Asink.Future.new()

    Asink.Runtime.exec(function()
        local Success, Response = pcall(function()
            return profile.ProfileStore.DataStore:UpdateAsync(profile.Key, function()
                local Metadata = profile.Metadata

                Metadata.LastUpdate = os.time()
                
                return {
                    ActiveSession = not release and profile.ActiveSession or nil;
                    Data = profile.Data;
                    Metadata = Metadata;
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

local function ReleaseProfile(profiles, profile)
    local Future = SaveProfile(profile, true)
    Future:map(function()
        profiles[profile.Key] = nil
    end)

    return Future
end

--< Module >--
return {
    LoadProfile = LoadProfile;
    SaveProfile = SaveProfile;
    ReleaseProfile = ReleaseProfile;
}