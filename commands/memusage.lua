--COMMAND TEMPLATE
local Object = {
	name = "memusage",
	usage = "Returns memory used by Lua",
	cmdNames = {'mem','memusage'},
	disabled = false
}



function Object.callback(self,args,rawarg)
    local used = math.floor(collectgarbage("count")/1000)
	args.msg:reply("Lua is using " .. used/GLOBAL_MAXMEM .. "% of a maximum " .. GLOBAL_MAXMEM ..  "MBytes. (".. used .. "MB).")
	return true
end

function Object:__init()
end

return Object