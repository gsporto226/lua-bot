local pp = require("pretty-print").prettyPrint

local tables = {

}

local mt = {}
mt.__newindex = function(self, field, value)
    self.__values[field] = value
end

mt.__index = function(self, field)
    if self.__values[field]then self.__lastQueried = Module.Deps.Commons.uv.hrtime() return self.__values[field] end
    return nil
end

mt.__pairs = function(self) return pairs(self.__values) end
mt.__ipairs = function(self) return ipairs(self.__values) end

function newTable()
    local t2 = {
        __lastQueried = 30,
        __values = {}
    }
    setmetatable(t2, mt)
    tables[#tables+1] = t2
    return t2
end

local t = newTable()
t["Asd"] = 2
t[0] = 1

local time = 0
function clearTable()
    for _,v in ipairs(tables) do
        if v.__lastQueried and v._lastQueried ~= -1 and time - v.__lastQueried >= 0 then 
            for k,_ in pairs(v) do v[k] = nil end
            for k,_ in ipairs(v) do v[k] = nil end
            v.__lastQueried = -1
        end
    end
end