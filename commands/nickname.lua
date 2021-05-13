--COMMAND TEMPLATE
local Object = {
	name = "Nickname",
	usage = "Sets this guild's bot nickname",
	cmdNames = {'nickname'}
}



function Object.callback(self,args,rawarg)
	local n = ""
	for _,v in ipairs(args) do
		if n == "" then 
			n = n .. v
		else
			n = n .. " " .. v
		end
	end
	args.msg.guild.me:setNickname(n)
	args.msg:reply("Set!")
	return true
end

function Object:__init()
end

return Object