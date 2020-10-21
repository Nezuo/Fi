--< Services >--
local RunService = game:GetService("RunService")

--< Modules >--
local Constants = require(script.Parent.Constants)
local Fi = nil

--< Variables >--
local LastAutoSave = os.clock()

--< Functions >--
local function OnHeartbeat()
    if not Fi.AutoSaveQueue:IsEmpty() then
        local AutoSaveInterval = Constants.AUTO_SAVE_INTERVAL / Fi.AutoSaveQueue:Length()

        if os.clock() - LastAutoSave > AutoSaveInterval then
            local Profile = Fi.AutoSaveQueue:Peek()

            -- Save the profile if it has been loaded longer than the auto save interval.
            if os.clock() - Profile.LoadedTimestamp > Constants.AUTO_SAVE_INTERVAL then
                Fi:SaveProfile(Profile)
            end

            LastAutoSave = os.clock()

            Fi.AutoSaveQueue:Shift()
        end
    end
end

--< Module >--
local AutoSave = {}

function AutoSave:Start()
    Fi = require(script.Parent)

    RunService.Heartbeat:Connect(OnHeartbeat)
end

function AutoSave:AddProfileToQueue(profile)
    Fi.AutoSaveQueue:Enqueue(profile)

    if Fi.AutoSaveQueue:Length() == 1 then
        LastAutoSave = os.clock()
    end
end

return AutoSave