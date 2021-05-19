local p = require("pretty-print").prettyPrint
local remove, insert = table.remove, table.insert

Utils = {}

function Utils.getDBOptions(string)
	string = string:gmatch("postgres://(%g+)")()
	return({string:gmatch("(%w+):")(),string:gmatch(":(%w+)@")(),string:gmatch("@(%g+):")(),string:gmatch(":(%d+)/")(),string:gmatch("/(%w+)")()})
end

function Utils.tableToString()
end	

function Utils.round(number)
	if number%2 ~= 0.5 then
		return math.floor(number+0.5)
	end
	return number-0.5
end

function Utils:createIfNotExists(path)
	if self.Deps.Commons.fs.existsSync(path) then return false end
	local lpath = string.match(path, "./.+/")
	self.Deps.Commons.fs.mkdirSync(lpath)
	return true
end

function Utils.formatFromSeconds(time)
	if type(time) == "string" then return time end
	if type(time) == "number" then
		if not time then
			time = 999
		end
		return string.format("%d:%d:%d", math.floor(time/3600), math.floor(time%3600/60), math.abs(math.floor(((time%3600/60)-Utils.round(time%3600/60))*60)))
	else
		return "missingno"
	end
end

function Utils.copyTable(t1, t2)
	if not t1 or not t2 then return nil end
	setmetatable(t2, getmetatable(t1))
    for k,v in ipairs(t1) do
        if type(v) == "table" then
            t2[k] = {}
            Utils.copyTable(v, t2[k])
        else
            t2[k] = v
        end
    end
    for k,v in pairs(t1) do
        if type(v) == "table" then
            t2[k] = {}
            Utils.copyTable(v, t2[k])
        else
            t2[k] = v
        end
    end
end

function Utils.copyTableI(t1, t2)
	if not t1 or not t2 then return nil end
	setmetatable(t2, getmetatable(t1))
    for k,v in ipairs(t1) do
        if type(v) == "table" then
            t2[k] = {}
            Utils.copyTable(v, t2[k])
        else
            t2[k] = v
        end
    end
end

function Utils.copyTableP(t1, t2)
	if not t1 or not t2 then return nil end
	setmetatable(t2, getmetatable(t1))
    for k,v in pairs(t1) do
        if type(v) == "table" then
            t2[k] = {}
            Utils.copyTable(v, t2[k])
        else
            t2[k] = v
        end
    end
end


function Utils.instanceOf(obj)
	local t = {}
	Utils.copyTable(obj, t)
	return t
end

function Utils.instanceOfI(obj)
	local t = {}
	Utils.copyTableI(obj, t)
	return t
end

function Utils.instanceOfP(obj)
	local t = {}
	Utils.copyTableP(obj, t)
	return t
end

function Utils.pp(obj)
	p(obj)
end

function Utils.purge(obj)
	if type(obj) == "table" then
		local omt = getmetatable(obj) or {}
		omt.__mode = "kv"
		setmetatable(obj, omt)
		for k,_ in pairs(obj) do
			if not string.find(k,"^__") then
				print("Purging " .. k)
				Utils.purge(k)
			end
		end
		for k,_ in ipairs(obj) do
			Utils.purge(k)
		end
	else
		obj = nil
	end
	collectgarbage()
end

---------------
--QUEUE OBJECT-
--------------
--[[
next returns next in queue
insert inserts at end

]]
local Queue = {}

function Queue:next()
	if #self <= 0 then return nil end
	return remove(self, 1) 
end

function Queue:insert(obj)
	return insert(self, #self + 1, obj)
end

function Queue:remove(id)
	if id > #self then return end
	return remove(id)
end

function Queue:getNextElements(n , i)
	if #self <= 0 then return nil end
	local start
	local elements
	if i then start = n elements = i else start = 1 elements = n end
    if elements > #self - start + 1 then elements = #self - start + 1 end
    elements = start + elements
	return function() 
        if start >= elements then return nil end
        start = start + 1
        return self[start - 1] 
	end
end

function Queue:clear()
	for k,_ in ipairs(self) do
		self[k] = nil
	end
end

function Queue:randomSort()
	if Events then
		local entries = Utils.instanceOfI(self)
		local i = 1
		local timer
		math.randomseed(os.time())
		timer = Events:createTimer(1, true, function()
			if not #entries > 0 then 
				Events:cancelTimer(timer)
			end
            self[i] =  remove(entries, math.random(#entries))
            i = i + 1
		end)
	else
		local entries = Utils.instanceOfI(self)
		local i = 1
        while #entries > 0 do
            self[i] =  remove(entries, math.random(#entries))
            i = i + 1
		end
    end
end

function Utils:newQueue() return self.instanceOf(Queue) end

--[[
	Basic Sets
]]

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

Utils.Set = Set

function Utils.__init()

end

return Utils