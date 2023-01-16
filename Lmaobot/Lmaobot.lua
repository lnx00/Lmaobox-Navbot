

local nav = require("sourcenav")
---@type AStar
local astar = require("A-Star")

---@type boolean, LNXlib
local libLoaded, Lib = pcall(require, "LNXlib")
assert(libLoaded, "LNXlib not found, please install it!")
assert(Lib.GetVersion() >= 0.80, "LNXlib version is too old, please update it!")

local FS, Fonts, Commands, Helpers, Notify = Lib.Utils.FileSystem, Lib.UI.Fonts, Lib.Utils.Commands, Lib.TF2.Helpers, Lib.UI.Notify

-- Read nav file
local navData = FS.Read("tf/maps/ctf_2fort.nav")
if not navData then
    error("Failed to read nav file!")
end

-- Parse nav file
local navMesh = nav.parse(navData)
print("Parsed " .. #navMesh.places .. " places, " .. #navMesh.areas .. " areas, " .. #navMesh.ladders .. " ladders.")

local areas = {}
local path = nil

local bDrawNodes = false
local bDrawCons = false
local bDrawPath = true

local bFollowPath = false

local pfCoroutine = nil
local startNode = nil
local goalNode = nil

local pfNotify = 0

for _, area in ipairs(navMesh.areas) do
    local cX = (area.north_west.x + area.south_east.x) / 2
    local cY = (area.north_west.y + area.south_east.y) / 2
    local cZ = (area.north_west.z + area.south_east.z) / 2
    
    if (areas[area.id] ~= nil) then
        print("Duplicate area id: " .. area.id)
    end
    areas[area.id] = { x = cX, y = cY, z = cZ, id = area.id, connections = area.connections }
end
print("Added " .. #areas .. " Areas")
navMesh = nil

local function validNodeFunc(node, neighbor)
    for dir = 1, 4 do
        local conDir = node.connections[dir]
        if conDir then
            for _, con in pairs(conDir.connections) do
                if con == neighbor.id then
                    if node.z + 70 > neighbor.z then
                        return true
                    end
                end
            end
        end
    end

    return false
end

local function OnDraw()
    draw.SetFont(Fonts.Verdana)
    draw.Color(255, 0, 0, 255)

    local me = entities.GetLocalPlayer()
    if not me then return end

    local myPos = me:GetAbsOrigin()

    -- Current Path
    if bDrawPath and path then
        -- Draw the id of each node and a line to the next node
        draw.Color(255, 255, 0, 255)
        for i, node in ipairs(path) do
            local nodePos = Vector3(node.x, node.y, node.z)
            if (myPos - nodePos):Length() > 1200 then goto continue end

            local nodeScreenPos = client.WorldToScreen(nodePos)
            if nodeScreenPos then
                draw.Text(nodeScreenPos[1], nodeScreenPos[2], tostring(node.id))
                if i < #path then
                    local nextNode = path[i + 1]
                    local nextNodePos = Vector3(nextNode.x, nextNode.y, nextNode.z)
                    local nextNodeScreenPos = client.WorldToScreen(nextNodePos)
                    if nextNodeScreenPos then
                        draw.Line(nodeScreenPos[1], nodeScreenPos[2], nextNodeScreenPos[1], nextNodeScreenPos[2])
                    end
                end
            end

            ::continue::
        end
    end

    -- Path coroutine
    for _ = 1, 5 do
        if pfCoroutine then
            local status, result = coroutine.resume(pfCoroutine, startNode, goalNode, areas, validNodeFunc)
            if result then
                print("Pathfinding finished!")
                Notify.Pop(pfNotify)
                Notify.Alert("Pathfinding finished!")
                path = result
                pfCoroutine = nil
            else
                draw.Color(255, 0, 0, 255)
                draw.Text(80, 200, "Pathfinding...")
            end
        end
    end

    --[[
    for id, area in pairs(areas) do
        local center = Vector3(area.x, area.y, area.z)
        local dist = (myPos - center):Length()
        if dist > 700 then goto continue end

        local screenPos = client.WorldToScreen(center)
        if not screenPos then goto continue end

        -- Node IDs
        if bDrawNodes then
            draw.Color(0, 255, 0, 255)
            draw.Text(screenPos[1], screenPos[2], tostring(id))
        end

        -- Connections
        if bDrawCons then
            draw.Color(0, 0, 255, 255)
            for dir = 1, 4 do
                local conDir = area.connections[dir]
                if conDir then
                    for _, con in pairs(conDir.connections) do
                        local conArea = areas[con]
                        if conArea then
                            local conPos = Vector3(conArea.x, conArea.y, conArea.z)
                            local conScreenPos = client.WorldToScreen(conPos)
                            if conScreenPos then
                                draw.Line(screenPos[1], screenPos[2], conScreenPos[1], conScreenPos[2])
                            end
                        end
                    end
                end
            end
        end

        ::continue::
    end
    ]]
end

local currentNode = 1

---@param userCmd UserCmd
local function OnCreateMove(userCmd)
    if not bFollowPath then return end
    if not path or currentNode == #path then
        bFollowPath = false return
    end

    local me = entities.GetLocalPlayer()
    if not me or not me:IsAlive() then return end

    local curNode = path[currentNode]
    local curPos = Vector3(curNode.x, curNode.y, curNode.z)
    Helpers.WalkTo(userCmd, me, curPos)

    local myPos = me:GetAbsOrigin()
    if (myPos - curPos):Length() < 25 then
        currentNode = currentNode + 1
    end
end

local function findPath(start, goal)
    pfNotify = Notify.Push({ Duration = 60, Title = "Pathfinding..." })
    pfCoroutine = coroutine.create(astar.path)

    startNode = areas[start]
    goalNode = areas[goal]
    if not startNode or not goalNode then
        error("Invalid start/goal")
        return
    end

    print("Finding path...")
end

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

    findPath(start, goal)
end)

Commands.Register("walk", function(args)
    if not path then
        print("No path active!")
        return
    end

    if bFollowPath then
        print("Stopping...")
        bFollowPath = false
        currentNode = 1
        return
    end

    bFollowPath = true
    print("Following path...")
end)

callbacks.Unregister("Draw", "LNX_PF_Draw")
callbacks.Register("Draw", "LNX_PF_Draw", OnDraw)

callbacks.Unregister("CreateMove", "LNX_PF_CreateMove")
callbacks.Register("CreateMove", "LNX_PF_CreateMove", OnCreateMove)