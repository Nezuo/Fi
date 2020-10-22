--< Services >--
local RunService = game:GetService("RunService")

--< Modules >--
local Constants = require(script.Parent.Constants)
local Fi = nil

--< Variables >--
local LastAutoSave = os.clock()

--< Module >--
local AutoSave = {}

function AutoSave:Update(clock, updateLastAutoSave)
    local SavedProfile = nil

    if Constants.AUTO_SAVE_INTERVAL > 0 and not Fi.AutoSaveQueue:IsEmpty() then
        local AutoSaveInterval = Constants.AUTO_SAVE_INTERVAL / Fi.AutoSaveQueue:Length()

        if clock - LastAutoSave >= AutoSaveInterval then
            local Profile = Fi.AutoSaveQueue:Peek()

            -- Save the profile if it has been loaded longer than the auto save interval.
            if clock - Profile.LoadedTimestamp >= Constants.AUTO_SAVE_INTERVAL then
                Fi:SaveProfile(Profile)

                SavedProfile = Profile
            end

            if updateLastAutoSave then
                LastAutoSave = clock
            end

            Fi.AutoSaveQueue:Shift()
        end
    end

    return SavedProfile
end

function AutoSave:Start(fi)
    Fi = fi

    if Constants.CAN_AUTO_SAVE then
        RunService.Heartbeat:Connect(function()
            self:Update(os.clock(), true)
        end)
    end
end

function AutoSave:AddProfileToQueue(profile)
    Fi.AutoSaveQueue:Enqueue(profile)

    if Fi.AutoSaveQueue:Length() == 1 then
        LastAutoSave = os.clock()
    end
end

return AutoSave