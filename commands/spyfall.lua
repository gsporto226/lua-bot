
local config

--COMMAND TEMPLATE
local Object = {
	name = "Spyfall",
	usage = "Game command, type {command}spyfall help for more options",
	cmdNames = {'spyfall','sf'}
}



function Object.callback(self,args,rawarg)
	local possibleCommands = {
	create = true,
	join = true,
	leave = true,
	start = true ,
	round = true,
	list = true,
	clear = true
	}
	local lobbyName = nil
	args[1] = string.lower(args[1])
	if possibleCommands[args[1]] then
			possibleCommands[args[1]] = false
			table.remove(args, 1)
			for _,v in ipairs(args) do
				if lobbyName then lobbyName = lobbyName .." ".. v else lobbyName = v end
			end
	else
		return false, "Unknown command, available commands {create, join, leave, start, list}"
	end
	local PlayerID = args.msg.author.id
	local PlayerName = args.msg.author.name
	local PlayerUserObject = args.msg.author

	if not possibleCommands.create then
		return Spyfall:AddLobby(lobbyName, PlayerID, PlayerName, PlayerUserObject, args.msg.channel)
	end

	if not possibleCommands.join then
		return Spyfall:PlayerJoin(PlayerID, PlayerName, lobbyName, PlayerUserObject)
	end

	if not possibleCommands.leave then
		return Spyfall:PlayerLeave(PlayerID, PlayerName)
	end

	if not possibleCommands.start then 
		return Spyfall:StartLobby(PlayerID, PlayerName)
	end

	if not possibleCommands.round then
		return Spyfall:EndRound(PlayerID)
	end

	if not possibleCommands.list then
		return Spyfall:ReturnLocations(PlayerUserObject)
	end

	if not possibleCommands.clear then
		return Spyfall:ClearSystem()
	end

	return true, "Success?"
end

function Object:__init()
	self.usage = "Game command, type " .. self.Deps.Config.Defaults.Prefix .."spyfall help for more options"
end

return Object