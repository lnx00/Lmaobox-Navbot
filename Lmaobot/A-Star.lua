--[[
	A-Star Algorithm for Lmaobox
	Credits: github.com/GlorifiedPig/Luafinding
]]

local Heap = require("Lmaobot.Heap")

---@alias PathNode { id : integer, x : number, y : number, z : number }

---@class AStar
local AStar = {}

local function HeuristicCostEstimate(nodeA, nodeB)
	return math.sqrt((nodeB.x - nodeA.x) ^ 2 + (nodeB.y - nodeA.y) ^ 2)
end

-- TODO: Don't do this here
---@return PathNode[]
local function GetAdjacentNodes(node, nodes)
	local adjacentNodes = {}

	for dir = 1, 4 do
		local conDir = node.c[dir]
		if conDir then
			for _, con in pairs(conDir.connections) do
				local conNode = nodes[con]
				if conNode then
					table.insert(adjacentNodes, conNode)
				end
			end
		end
	end

	return adjacentNodes
end

local function ReconstructPath(current)
	local path = { current }
	while current.previous do
		current = current.previous
		table.insert(path, current)
	end

	return path
end

---@param start PathNode
---@param goal PathNode
---@return PathNode[]|nil
function AStar.Path(start, goal, nodes)
	local openSet, closedSet = Heap.new(), {}
	local gScore, fScore = {}, {}
	gScore[start.id] = 0
	fScore[start.id] = gScore[start.id] + HeuristicCostEstimate(start, goal)

	openSet.Compare = function(a, b) return fScore[a.id] < fScore[b.id] end
	openSet:push(start)

	while not openSet:empty() do
		---@type PathNode
		local current = openSet:pop()
		local currentID = current.id

		if not closedSet[currentID] then
			if currentID == goal.id then
				return ReconstructPath(current)
			end

			closedSet[currentID] = true

			local adjacentNodes = GetAdjacentNodes(current, nodes)
			for _, neighbor in ipairs(adjacentNodes) do
				local neighborID = neighbor.id
				if not closedSet[neighborID] then
					local tentativeGScore = gScore[current.id] + HeuristicCostEstimate(current, neighbor)

					local neighborGScore = gScore[neighborID]
					if not neighborGScore or tentativeGScore < neighborGScore then
						gScore[neighborID] = tentativeGScore
						fScore[neighborID] = gScore[neighborID] + HeuristicCostEstimate(neighbor, goal)
						neighbor.previous = current
						openSet:push(neighbor)
					end
				end
			end
		end
	end

	return nil
end

return AStar
