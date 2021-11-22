
local discordia
local enums
local logger
local client

local fs = require('fs')
local joinPath = require('path').join
local readFileSync, scanDirSync = fs.readFileSync, fs.scandirSync
local insert,getn = table.insert,table.getn


local Send = {
	name = "Send",
	commands = {}
}

function Send:__init()
	discordia = self.Deps.Discordia
	enums = self.Deps.Enums
	logger = self.Deps.Logger
    client = self.Deps.Client
	return Send
end


function Send:send(id, args,rawarg)
    client:getUser(id):getPrivateChannel():send('oi')
end

return Send