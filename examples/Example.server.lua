local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local Fi = require(ServerScriptService.Fi)

local PlayerProfiles = Fi:GetProfileStore("PlayerData")

local function OnPlayerAdded(player)
    local Profile = PlayerProfiles:LoadProfileAsync("Player" .. player.UserId)

    while true do
        print(Profile.Data.Coins)

        Profile.Data.Coins += 1

        wait(1)
    end
end

Players.PlayerAdded:Connect(OnPlayerAdded)