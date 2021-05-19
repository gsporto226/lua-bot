local Utils = require("./modules/Utils")
local Queue = {1,2,3,4,5,6,7,8,9,10}
local remove, insert = table.remove, table.insert
local p = require("pretty-print").prettyPrint

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
