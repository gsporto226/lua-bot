local Module = {
    name = "Self Clearing Table",
    tables = {},
    activeTables = 0,
    timeLimit = 45 * 1000 * 1000000
}


local SCTable = {
    __lastQueried = -1,
    __values = {},
    __active = false
}

function Module:createClearTimer()
    Events:createTimer(1000, true, function(timer)
        if self.activeTables <= 0 then
            Events:cancelTimer(timer)
            return
        end
        local time = self.Deps.Commons.uv.hrtime()
        for _,v in ipairs(self.tables) do
            if v.__lastQueried and v._lastQueried ~= -1 and time - v.__lastQueried >= self.timeLimit then 
                for k,_ in pairs(v.__values) do v[k] = nil end
                for k,_ in ipairs(v.__values) do v[k] = nil end
                v.__lastQueried = -1
                v.__active = false  
                self.activeTables = self.activeTables - 1
            end
        end
    end)
end

function Module:activateTable(table)
    if not table.__active then 
        if self.activeTables <= 0 then
            self:createClearTimer()
        end
        self.activeTables = self.activeTables + 1
        table.__active = true
        self.__lastQueried = Module.Deps.Commons.uv.hrtime()
    end
end

local mt = {}
mt.__newindex = function(self, field, value)
    Module:activateTable(self)
    self.__values[field] = value
end

mt.__index = function(self, field)
    Module:activateTable(self)
    return self.__values[field]
end

mt.__pairs = function(self) Module:activateTable(self) return pairs(self.__values) end
mt.__ipairs = function(self) Module:activateTable(self) return ipairs(self.__values) end


function Module:new()
    local tbl = Utils.instanceOf(SCTable)
    setmetatable(tbl, mt)
    tbl.__lastQueried = self.Deps.Commons.uv.hrtime()
    self.tables[#self.tables+1] = tbl
    self:activateTable(tbl)
    return tbl
end


function Module:__init()
end 

function Module:__ready()
end

return Module