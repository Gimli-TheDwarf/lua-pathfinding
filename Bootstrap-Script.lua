
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

local collisionGroups = 
{
	collisionGroupNpcs = "CollisionGroupNpcs",
	collisionGroupPlayers = "CollisionGroupPlayers",
	collisionGroupScanPlayersOnly = "ScanPlayersOnly"
}

local function setPcall(collisionGroup)
	local pass, result = pcall(function()
		PhysicsService:RegisterCollisionGroup(collisionGroup)
	end)
	return pass, result
end

local function setCollisionRules()
	PhysicsService:CollisionGroupSetCollidable(collisionGroups.collisionGroupScanPlayersOnly, "Default", false)
	PhysicsService:CollisionGroupSetCollidable(collisionGroups.collisionGroupScanPlayersOnly, collisionGroups.collisionGroupPlayers, true)
end

local function pcallList()
	for key, groupItem in pairs(collisionGroups) do
		local status, returnText = setPcall(groupItem)
		if not status  then
			warn("Didnt register the collision group: ", returnText, "\n Collision group: ", groupItem)
		end
	end
	setCollisionRules()
end

local function setBaseParts(character)
	for _, basePart in ipairs(character:GetChildren()) do
		if basePart:IsA("BasePart") then
			basePart.CollisionGroup = collisionGroups.collisionGroupPlayers
		end
	end
end

local function setCollisionGroups(player)
	if player.Character ~= nil then --if player character already exists
		print("character already exists")
		local character = player.Character
		setBaseParts(character)
	end
	player.CharacterAdded:Connect(function(character)
		setBaseParts(character)
	end)
end

pcallList()

local initialPlayers = Players:GetPlayers() 

for _, player in ipairs(initialPlayers) do
	setCollisionGroups(player)
end

Players.PlayerAdded:Connect(function(Player)
	setCollisionGroups(Player)
end)