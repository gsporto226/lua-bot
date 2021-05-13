--ALL WE NEED IS A TABLE WITH NAME,COMMANDTAG,HINT AND CALLBACK
local pp = require("pretty-print")

local Object = {
	name = "help",
	usage = "help",
	cmdNames = {'help','?'}
}



function Object.callback(self,args,rawarg)
	local list = {}
	for _,v in pairs(Commands._cmds) do
		local names = ''
		for _,k in ipairs(v.cmdNames) do
			names = names .. " " .. k
		end
		list[names] = v.usage
	end
	args.msg:reply{embed = Response.embeds.keyValueList("Command list",list)}
	
	list = nil
	return true
end

function Object:__init()
end

return Object