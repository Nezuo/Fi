local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local Fi = require(ServerScriptService.Fi)

local PlayerProfiles = Fi:GetProfileStore("PlayerData7")

local Profiles = {}

local function OnPlayerAdded(player)
    print("Loading data...")

    PlayerProfiles:LoadProfile("Player" .. player.UserId):map(function(result)
        local Success, Response = result:unpack()

        print("Loaded data.")

        if not Success then
            warn(Response)
        else
            Response.Data.Coins = Response.Data.Coins or 0

            Profiles[player] = Response
        end
    end)
end

local function OnPlayerRemoving(player)
    local Profile = Profiles[player]

    if Profile then
        Profiles[player] = nil

        Fi:ReleaseProfile(Profile)
    end
end

Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(OnPlayerRemoving)

while true do
    for player,profile in pairs(Profiles) do
        profile.Data.Coins += 1

        print(player.Name .. " has " .. profile.Data.Coins .. " coins.")
    end

    wait(1)
end