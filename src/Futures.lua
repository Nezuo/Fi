--< Modules >--
local Asink = require(script.Parent.Asink)

--< Functions >--
local function SaveProfile(profile, release)
    local Future, Resolve = Asink.Future.new()

    Asink.Runtime.exec(function()
        local Success, Response = pcall(function()
            return profile.ProfileStore.DataStore:UpdateAsync(profile.Key, function()
                return {
                    ActiveSession = not release and profile.ActiveSession or nil;
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

local function ReleaseProfile(profiles, profile)
    local Future = SaveProfile(profile, true)
    Future:map(function()
        profiles[profile.Key] = nil
    end)

    return Future
end

--< Module >--
return {
    SaveProfile = SaveProfile;
    ReleaseProfile = ReleaseProfile;
}