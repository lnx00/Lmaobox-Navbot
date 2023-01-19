local aStar = require("Lmaobot.A-Star")

---@alias Connection { count: integer, connections: integer[] }
---@alias Node { x: number, y: number, z: number, id: integer, c: { [1]: Connection, [2]: Connection, [3]: Connection, [4]: Connection } }

local function DistTo(a, b)
    return math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2 + (a.z - b.z) ^ 2)
end

---@class Pathfinding
---@field public CurrentPath Node[]
local Navigation = {
    CurrentPath = {}
}

local Nodes = {}

---@param nodes Node[]
function Navigation.SetNodes(nodes)
    Nodes = nodes
end

---@return Node[]
function Navigation.GetNodes()
    return Nodes
end

---@param pos Vector3 | { x:number, y:number, z:number }
---@return Node
function Navigation.GetClosestNode(pos)
    local closestNode = nil
    local closestDist = math.huge

    for _, node in pairs(Nodes) do
        local dist = DistTo(node, pos)
        if dist < closestDist then
            closestNode = node
            closestDist = dist
        end
    end

    return closestNode
end

-- Returns all adjacent nodes of the given node
local function GetAdjacentNodes(node, nodes)
	local adjacentNodes = {}

	for dir = 1, 4 do
		local conDir = node.c[dir]
        for _, con in pairs(conDir.connections) do
            local conNode = nodes[con]
            if conNode then
                table.insert(adjacentNodes, conNode)
            end
        end
	end

	return adjacentNodes
end

---@param startID integer
---@param goalID integer
function Navigation.FindPath(startID, goalID)
    local startNode = Nodes[startID]
    if not startNode then
        warn(string.format("Start node %d not found!", startID))
        return
    end

    local goalNode = Nodes[goalID]
    if not goalNode then
        warn(string.format("Goal node %d not found!", goalID))
        return
    end

    local path = aStar.Path(startNode, goalNode, Nodes, GetAdjacentNodes)
    if not path then
        error(string.format("Failed to find path from %d to %d!", startID, goalID))
        return
    end

    Navigation.CurrentPath = path
end

return Navigation
