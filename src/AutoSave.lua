--< Services >--
local RunService = game:GetService("RunService")

--< Modules >--
local Constants = require(script.Parent.Constants)
local Queue = require(script.Parent.Queue)

--< Variables >--
local AutoSaveQueue = Queue.new()
local LastAutoSave = os.clock()

--< Functions >--
local function OnHeartbeat()
    if not AutoSaveQueue:IsEmpty() then
        local AutoSaveInterval = Constants.AUTO_SAVE_INTERVAL / AutoSaveQueue:Length()

        if os.clock() - LastAutoSave > AutoSaveInterval then
            local Profile = AutoSaveQueue:Peek()

            -- Save the profile if it has been loaded longer than the auto save interval.
            if os.clock() - Profile.LoadedTimeStamp > Constants.AUTO_SAVE_INTERVAL then
                --Fi:SaveProfile(Profile)
            end

            LastAutoSave = os.clock()

            AutoSaveQueue:Shift()
        end
    end
end

--< Module >--
local AutoSave = {}

function AutoSave:AddProfileToQueue(profile)
    AutoSaveQueue:Enqueue(profile)

    if AutoSaveQueue:Length() == 1 then
        LastAutoSave = os.clock()
    end
end

RunService.Heartbeat:Connect(OnHeartbeat)

return AutoSave