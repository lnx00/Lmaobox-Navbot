--[[
    Heap implementation in Lua
    Credits: github.com/GlorifiedPig/Luafinding
]]

local function findLowest(a, b)return a < b end

---@class Heap
local Heap = {
    _data = {},
    _size = 0,
    Compare = findLowest,
}
Heap.__index = Heap
setmetatable(Heap, Heap)

---@param compare? fun(a: any, b: any): boolean
---@return Heap
function Heap.new(compare)
    local self = setmetatable({}, Heap)
    self._data = {}
    self.Compare = compare or findLowest
    self._size = 0

    return self
end

---@param heap Heap
---@param index integer
local function sortUp(heap, index)
    if index <= 1 then return end
    local pIndex = index % 2 == 0 and index / 2 or (index - 1) / 2

    if not heap.Compare(heap._data[pIndex], heap._data[index]) then
        heap._data[pIndex], heap._data[index] = heap._data[index], heap._data[pIndex]
        sortUp(heap, pIndex)
    end
end

---@param heap Heap
---@param index integer
local function sortDown(heap, index)
    local leftIndex, rightIndex, minIndex
    leftIndex = index * 2
    rightIndex = leftIndex + 1
    
    if rightIndex > heap._size then
        if leftIndex > heap._size then
            return
        else
            minIndex = leftIndex
        end
    else
        if heap.Compare(heap._data[leftIndex], heap._data[rightIndex]) then
            minIndex = leftIndex
        else
            minIndex = rightIndex
        end
    end

    if not heap.Compare(heap._data[index], heap._data[minIndex]) then
        heap._data[index], heap._data[minIndex] = heap._data[minIndex], heap._data[index]
        sortDown(heap, minIndex)
    end
end

function Heap:empty()
    return self._size == 0
end

function Heap:clear()
    self._data, self._size, self.Compare = {}, 0, self.Compare or findLowest
    return self
end

function Heap:push(item)
    if item then
        self._size = self._size + 1
        self._data[self._size] = item
        sortUp(self, self._size)
    end

    return self
end

function Heap:pop()
    local root
    if self._size > 0 then
        root = self._data[1]
        self._data[1] = self._data[self._size]
        self._data[self._size] = nil
        self._size = self._size - 1
        if self._size > 1 then
            sortDown(self, 1)
        end
    end

    return root
end

return Heap
