--COMMAND TEMPLATE
local Object = {
	name = "Command",
	usage = "No use, its just a template and should be disabled",
	cmdNames = {'command','template'},
	disabled = true
}



function Object.callback(self,args,rawarg)
	args.msg:reply("Template for commands, without a reason to exist, It often gets depressed about its own existance. Either way, here is its usage: "..self.usage)
	return true
end

function Object:__init()
end

return Object