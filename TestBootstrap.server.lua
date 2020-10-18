--< Services >--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--< Modules >--
local TestEZ = require(ReplicatedStorage.TestEZ)

--< Start >--
TestEZ.TestBootstrap:run({ ServerScriptService.Fi })