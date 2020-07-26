local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local PlayerStore = DataStoreService:GetDataStore("PlayerData")

local function GetData(player)
    local Success,Result = pcall(PlayerStore.GetAsync, PlayerStore, "Player" .. player.UserId)

    if Success then
        print("Success!")
    else
        error(Result)
    end
end

local function OnPlayerAdded(player)
    GetData(player)
end

local function OnPlayerRemoving(player)
    
end

Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(OnPlayerRemoving)

return nil