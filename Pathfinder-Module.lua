local Pathfinder = {}

local range = 40
local minDistance = 10
local minPointDistance = 15
local hbConnections = {}
local npcWaypoints = {}
local guardToken = {}

local folder = workspace.parts
local pathFindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

function Pathfinder.endRoam(entity)
	entity:SetAttribute("Roaming", false)
end

local function HbEnd(npc)
	if not npc then return end
	hbConnections[npc]:Disconnect()
	hbConnections[npc] = nil
end

local function DropGuard(npc)
	npc:SetAttribute("Safe", false)
	HbEnd(npc)
	task.delay(10, function()
		if npc and npc.Parent then
			npc:SetAttribute("Safe", true)
		end
	end)
end

local function HbStart(npc, ovPr, detectTime)
	if not npc:GetAttribute("Safe") then return end
	if not npc then return end
	
	local oldEntry = hbConnections[npc]
	if oldEntry then
		oldEntry:Disconnect()
		hbConnections[npc] = nil
	end
	
	local total = 0
	
	hbConnections[npc] = RunService.Heartbeat:Connect(function(hbTime)
		total += hbTime
		if total < detectTime then return end
		
		total -= detectTime
		local Items
		Items = workspace:GetPartBoundsInRadius(npc.HumanoidRootPart.Position, 60, ovPr)
		print("HB NPC NAME: ", npc.Name)
		print("HB ITEMS FOUND: ", #Items)
		if #Items ~= 0 then do
			print("something was found")
			Pathfinder.endRoam(npc)
			table.clear(npcWaypoints[npc])
			--once finished moving to position, look for enemy visually, after that wait 10 seconds before resuming ordinary behaviour
		end
		end
	end)
end

local function runDetect(npc, ovPr)
	local Items
	Items = workspace:GetPartBoundsInRadius(npc.HumanoidRootPart.Position, 150, ovPr)
	print("NPC NAME: ", npc.Name)
	print("ITEMS FOUND: ", #Items)
	if #Items > 0 then do
			print("person found")
			npc:SetAttribute("Safe", false)
			HbStart(npc, ovPr, 2)	
		end
	end
end

local function followWaypoints(npc, path, overlapParms)

	local humanoid = npc.Humanoid
	for _, waypoint in ipairs(npcWaypoints[npc]) do
		
		if npc:GetAttribute("Safe") then
			runDetect(npc, overlapParms)
		end		

		local part = Instance.new("Part")
		print(waypoint)
		part.Position = waypoint + Vector3.new(0,2,0)
		part.Size = Vector3.new(2,2,2)
		part.Color = Color3.new(0, 1, 0)
		part.Anchored = true
		part.CanCollide = false
		part.Parent = folder

		local rootPart = npc.HumanoidRootPart.Position
		path:ComputeAsync(rootPart, waypoint)

		if path.Status ~= Enum.PathStatus.Success then
			continue
		end

		local computedWaypoints = path:GetWaypoints()
		--wp datatypes
		--wp.Position (where to go)z	
		--wp.Action (what kind of movement is required)
		--wp.Label (extra info for custom navigation)

		for i = 2, #computedWaypoints do
			local wp = computedWaypoints[i]
			--local part = Instance.new("Part")
			--print(wp)
			--part.Position = wp.Position
			--part.Size = Vector3.new(1,1,1)
			--part.Color = Color3.new(1, 0, 0)
			--part.Anchored = true
			--part.CanCollide = false
			--part.Parent = folder

			if wp.Action == Enum.PathWaypointAction.Jump then
				humanoid.Jump = true
			end

			humanoid:MoveTo(wp.Position)
			local reachedEnd = humanoid.MoveToFinished:Wait()

			if not reachedEnd then
				break
			end
		end
		folder:ClearAllChildren()
		task.wait(math.random(1,2))
	end
end

local function buildWorldWaypoints(x, z, waypointArray)
	print("BUILDING WORLD WAYPOINT")
	local workspace = game:GetService("Workspace")
	local rayOrigin = Vector3.new(x,700,z)
	local rayDirection = Vector3.new(0,-2000,0)
	local params = RaycastParams.new()

	params.IgnoreWater = true
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = {workspace.Ground}

	local rayCastResult = workspace:Raycast(rayOrigin, rayDirection, params)

	if rayCastResult == nil then
		return false
	end

	local waypointPosition = Vector3.new(x, rayCastResult.Position.Y + 2, z)
	table.insert(waypointArray, waypointPosition)
	return true

end


local function insertWaypoints(algn, dstn, characterPosition, waypointArray)

	print("Inserting waypoints")
	local degrees = math.rad(algn)	
	local positionX = characterPosition.X + dstn * math.cos(degrees) 
	local positionZ = characterPosition.Z + dstn * math.sin(degrees)

	local ok = true

	if dstn < minDistance then
		print("Distance from npc aint long enough, try again")
		return false
	end

	if #waypointArray == 0 then
		print("inserting first item")

	else
		for _, worldPoint in ipairs(waypointArray) do
			local worldPointX = worldPoint.X
			local worldPointZ = worldPoint.Z
			local distanceCheck = math.sqrt(math.pow((positionX-worldPointX),2) + math.pow((positionZ-worldPointZ),2))

			if distanceCheck < minPointDistance then
				ok = false
				print("fail")
				break
			end
		end

		if ok == true then
			print("seems ok")
		else
			return false
		end
	end

	local vector3Waypoint = buildWorldWaypoints(positionX, positionZ, waypointArray)

	if vector3Waypoint == false then
		print(`raycasting target is not a part of the "ground" folder`)
		return false
	else
		print(`raycasting target successfully acquired`)
		return true
	end
end

local function setWaypoints(Entity, arrayWaypoints)
	print("setting waypoints")
	print("ENTITY: ", Entity)
	local centerPosition = Entity.HumanoidRootPart.Position
	local alignment = 0
	local distance = 0 

	local randomizedWaypointCount = math.random(4,6)

	while #arrayWaypoints < randomizedWaypointCount do
		alignment = math.random(0, 360) -- between 0 and 360 degrees
		distance = math.random(5, range) -- the distance from the center position 
		insertWaypoints(alignment, distance, centerPosition, arrayWaypoints)
	end
end

local function startRoam(entity, overlapParams, path)
	while entity:GetAttribute("Roaming") do
		table.clear(npcWaypoints[entity])
		print("________________")
		print("LOOPING..")
		print("CURRENT WAYPOINTS: " ,#npcWaypoints[entity])

		setWaypoints(entity, npcWaypoints[entity])
		followWaypoints(entity, path, overlapParams)
		task.wait(math.random(4,6))
	end
end

function Pathfinder.Roam(entity)
	
	entity.HumanoidRootPart:SetNetworkOwner(nil)
	npcWaypoints[entity] = {}	
	local path = pathFindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true,
		AgentJumpHeight = 7,
		AgentMaxSlope = 45,
		WaypointSpacing = 8
	})

	if entity:GetAttribute("Roaming") then
		warn("Roaming is already active: ", entity.Name)
		return
	end
	entity:SetAttribute("Roaming", true)
	entity:SetAttribute("Safe", true)

	local overlapParms = OverlapParams.new()
	overlapParms.CollisionGroup = "ScanPlayersOnly" -- will ignore any parts that the collision group is set not to collide with
	overlapParms.FilterType = Enum.RaycastFilterType.Exclude
	overlapParms.FilterDescendantsInstances = {entity} -- excludes the following from the overlapParameters
	
	print("beginning roam")
	startRoam(entity, overlapParms, path)
end

return Pathfinder