local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local Fi = require(ServerScriptService.Fi)

local PlayerProfiles = Fi:GetProfileStore("PlayerData")

local Profiles = {}

local function OnPlayerAdded(player)
    local Profile = PlayerProfiles:LoadProfileAsync("Player" .. player.UserId)

    Profiles[player] = Profile

    while true do
        print(player.Name .. ": " .. Profile.Data.Coins)

        Profile.Data.Coins += 1

        wait(1)
    end
end

local function OnPlayerRemoving(player)
    Fi:SaveProfile(Profiles[player])
    Profiles[player] = nil
end

Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(OnPlayerRemoving)