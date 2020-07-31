local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local Fi = require(ServerScriptService.Fi)

local PlayerProfiles = Fi:GetProfileStore("PlayerData")

local Profiles = {}

local function OnPlayerAdded(player)
    PlayerProfiles:LoadProfileAsync("Player" .. player.UserId):map(function(result)
        local Success, Response = result:unpack()

        if not Success then
            warn(Response)
        else
            Profiles[player] = Response

            while true do
                print(player.Name .. ": " .. Response.Data.Coins)
        
                Response.Data.Coins += 1
        
                wait(1)
            end
        end
    end)
end

local function OnPlayerRemoving(player)
    if Profiles[player] then
        Fi:SaveProfile(Profiles[player])
        Profiles[player] = nil
    end
end

Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(OnPlayerRemoving)