
local ServerScriptService = game:GetService("ServerScriptService")
local pathFinder = require(ServerScriptService:WaitForChild("Pathfinder"))

local npc = script.Parent
print("npc: ", npc.Name)
print("roam: " ,pathFinder.Roam)

pathFinder.Roam(npc)