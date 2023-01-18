--[[ Annotations ]]
---@alias NavConnection { count: integer, connections: integer[] }
---@alias NavNode { id: integer, x: number, y: number, z: number, c: { [1]: NavConnection, [2]: NavConnection, [3]: NavConnection, [4]: NavConnection } }

--[[ Imports ]]
local sourceNav = require("Lmaobot/SourceNav")

---@type AStar
local aStar = require("Lmaobot/A-Star")

---@type boolean, LNXlib
local libLoaded, Lib = pcall(require, "LNXlib")
assert(libLoaded, "LNXlib not found, please install it!")
assert(Lib.GetVersion() >= 0.94, "LNXlib version is too old, please update it!")

-- Unload package for debugging
Lib.Utils.UnloadPackages("Lmaobot")

local Notify, FS, Fonts, Commands = Lib.UI.Notify, Lib.Utils.FileSystem, Lib.UI.Fonts, Lib.Utils.Commands
local Log = Lib.Utils.Logger.new("Lmaobot")

Notify.Alert("Lmaobot loaded!")

--[[ Variables ]]

local options = {
    memoryUsage = true,
    drawNodes = false,
    drawPath = true,
}

---@type NavNode[]
local navNodes = {}

---@type NavNode[]|nil
local currentPath = nil

--[[ Functions ]]

-- Loads the nav file of the current map
local function LoadNavFile()
    local mapFile = engine.GetMapName()
    local navFile = string.gsub(mapFile, ".bsp", ".nav")

    -- Read nav file
    local rawNavData = FS.Read("tf/" .. navFile)
    assert(rawNavData, "Failed to read nav file!")

    -- Parse nav file
    local navData = sourceNav.parse(rawNavData)
    Log:Info("Parsed %d areas", #navData.areas)

    -- Convert nav data to usable format
    navNodes = {}
    for _, area in ipairs(navData.areas) do
        local cX = (area.north_west.x + area.south_east.x) / 2
        local cY = (area.north_west.y + area.south_east.y) / 2
        local cZ = (area.north_west.z + area.south_east.z) / 2

        navNodes[area.id] = { x = cX, y = cY, z = cZ, id = area.id, c = area.connections }
    end

    -- Free memory
    rawNavData, navData = nil, nil
    collectgarbage()
end

---@param node NavNode
---@param neighbor NavNode
---@return boolean
local function IsValidConnection(node, neighbor)
    for dir = 1, 4 do
        local conDir = node.c[dir]
        if conDir then
            for _, con in pairs(conDir.connections) do
                if con == neighbor.id then
                    --if node.z + 70 > neighbor.z then
                        return true
                    --end
                end
            end
        end
    end

    return false
end

-- Updates the current path to the given goal
local function FindPath(start, goal)
    local startNode = navNodes[start]
    if not startNode then
        Log:Error("Start node %d not found!", start)
        return
    end

    local goalNode = navNodes[goal]
    if not goalNode then
        Log:Error("Goal node %d not found!", goal)
        return
    end

    local path = aStar.path(startNode, goalNode, navNodes, IsValidConnection)
    if not path then
        Log:Error("Failed to find path from %d to %d!", start, goal)
        return
    end

    currentPath = path
end

local function OnDraw()
    draw.SetFont(Fonts.Verdana)
    draw.Color(255, 0, 0, 255)

    local me = entities.GetLocalPlayer()
    if not me then return end

    local myPos = me:GetAbsOrigin()

    -- Memory usage
    if options.memoryUsage then
        local memUsage = collectgarbage("count")
        draw.Text(20, 120, string.format("Memory usage: %.2f MB", memUsage / 1024))
    end

    -- Draw all nodes
    if options.drawNodes then
        draw.Color(0, 255, 0, 255)

        for id, node in pairs(navNodes) do
            local nodePos = Vector3(node.x, node.y, node.z)
            local dist = (myPos - nodePos):Length()
            if dist > 700 then goto continue end

            local screenPos = client.WorldToScreen(nodePos)
            if not screenPos then goto continue end

            -- Node IDs
            draw.Text(screenPos[1], screenPos[2], tostring(id))

            ::continue::
        end
    end

    -- Draw current path
    if options.drawPath and currentPath then
        draw.Color(255, 255, 0, 255)

        local pathSize = #currentPath
        for i, node in ipairs(currentPath) do
            local nodePos = Vector3(node.x, node.y, node.z)
            if (myPos - nodePos):Length() > 1200 then goto continue end

            local screenPos = client.WorldToScreen(nodePos)
            if not screenPos then goto continue end

            draw.Text(screenPos[1], screenPos[2], tostring(node.id))
            if i < pathSize then
                local nextNode = currentPath[i + 1]
                local nextNodePos = Vector3(nextNode.x, nextNode.y, nextNode.z)
                local nextScreenPos = client.WorldToScreen(nextNodePos)
                if nextScreenPos then
                    draw.Line(screenPos[1], screenPos[2], nextScreenPos[1], nextScreenPos[2])
                end
            end

            ::continue::
        end
    end
end

callbacks.Unregister("Draw", "LNX.Lmaobot.Draw")
callbacks.Register("Draw", "LNX.Lmaobot.Draw", OnDraw)

Commands.Register("pf_reload", function()
    LoadNavFile()
end)

Commands.Register("pf", function(args)
    if args:size() ~= 2 then
        print("Usage: pf <Start> <Goal>")
        return
    end

    local start = tonumber(args:popFront())
    local goal = tonumber(args:popFront())

    if not start or not goal then
        print("Start/Goal must be numbers!")
        return
    end

    FindPath(start, goal)
end)

LoadNavFile()