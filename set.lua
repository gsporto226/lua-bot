local Utils = require('./modules/Utils')

local Set = {}

local mt = {}

local function printSet(set)
    for k,v in pairs(set) do
        if tonumber(k) then print(k) end
    end
end

function mt.insert(self, n)
    n = tonumber(n)
    if not self or not n then return false end
    if not self[n] then self[n] = true self.__size = self.__size + 1 end
    return true
end

function mt.remove(self, n)
    n = tonumber(n)
    if not self or not n then return false end
    if self[n] then self[n] = nil self.__size = self.__size - 1 end
    return true
end

function mt.__add(a, b)
    local result = Set()
    for k, _ in pairs(a) do result:insert(k) end
    for k, _ in pairs(b) do result:insert(k) end
    return result
end

function mt.__mul(a, b)
    local result = Set()
    for k, _ in pairs(a) do
        if b[k] then result:insert(k) end
    end
    return result
end

function mt.__sub(a, b)
    local result = Utils.instanceOf(a)
	for k, _ in pairs(b) do result:remove(k) end
	return result
end

setmetatable(Set, {__call = 
function(self, t2)
	if t2 and type(t2) == "table" then
		mt.__index = mt
		local tbl = setmetatable({__size = 0}, mt)
        for _, v in ipairs(t2) do
			tbl:insert(v)
		end
		return tbl
	end
    mt.__index = mt
    return setmetatable({__size = 0}, mt)
end})


local set1 = Set({1,2,3,4})
local set2 = Set{2,3,4}
--printSet(set2)
--print(set2:remove(2))
printSet(set1*set2)