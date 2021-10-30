
local discordia
local enums
local logger

local fs = require('fs')
local joinPath = require('path').join
local readFileSync, scanDirSync = fs.readFileSync, fs.scandirSync
local insert,getn = table.insert,table.getn


local Commands = {
	name = "Commands",
	commands = {}
}

function Commands:__init()
	discordia = self.Deps.Discordia
	enums = self.Deps.Enums
	logger = self.Deps.Logger
	self._cmds = self:loadCommands("./commands")
	return Commands
end

function Commands:loadCommands(path)
	local files = {}
	local commands = {}
	local time = 0
	--Scan modules file in path
	for k,v in scanDirSync(path) do
		if k:find('.lua',-4) then
			insert(files,k)
		end
	end
	--Iterate through files and try to load them
	for _,v in pairs(files) do
		local n = v:gsub(".lua","")
		local s,e = pcall(function()
				local data = assert(readFileSync(joinPath(path,v)))
				local code = assert(loadstring(data))
				setfenv(code,getfenv())
				local cmdObject = code()
				if cmdObject.disabled then
					cmdObject = nil
				else
					cmdObject.Deps = self.Deps
					for _,v in ipairs(cmdObject.cmdNames) do
						commands[v] = cmdObject
					end
					self.commands[#self.commands+1] = {n, cmdObject}
				end
			end)
		if s then logger:log(enums.logLevel.info,"[Command] Loaded ".. n) else logger:log(enums.logLevel.error," .. [Command] Failed to load " .. v .. " with error : \n" .. e) end 
	end
	return commands
end

function Commands:initCommands()
	logger:log(enums.logLevel.info, "[Command] Initializing commands.")
	for _, v in ipairs(self.commands) do 
		local s,e = pcall(function() v[2]:__init() end)
		if s then logger:log(enums.logLevel.info,"[Command] Intialized ".. v[1]) else logger:log(enums.logLevel.error," .. [Command] Failed to initialize " .. v[1] .. " with error : \n" .. e) end 
	end
end

function Commands:Run(command, args,rawarg)
	local success = false
	local reason = "Command does not exist!"
	local s,e = pcall(function() success, reason = self._cmds[command]:callback(args,rawarg) end)
	reason = reason or ("Unknown error while attempting to run command")
	print(success, reason)
	if not s then logger:log(enums.logLevel.error," [Command] Failed calling command " .. command .. " with arguments \n" .. " with error \n" .. e) end
	if not success then args.msg:reply{embed = Response.embeds.invalidCommand(command, reason)} return false end
end

return Commands