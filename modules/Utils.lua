local p = require("pretty-print").prettyPrint

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

function Utils.pcount(table)
	if table and type(table) == 'table' then
		local c = 0
		for _, _ in pairs(table) do
			c = c + 1
		end
		return c
	else
		error('Expected argument to be a table')
	end
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

function Utils.pp(obj)
	p(obj)
end

function Utils.__init()

end

return Utils