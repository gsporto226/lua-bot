local Discordia = require('discordia')
local fs = require('fs')
local joinPath = require('path').join
local Json = require('json')
local getenv = require('os').getenv

--Global variables
_G["dev"] = getenv("BOT_ISDEV") == "true" or false
_G["GLOBAL_MAXMEM"] = tonumber(getenv("BOT_MAXMEM")) or 512 --In MBytes

local Client = Discordia.Client()
local Logger = Discordia.Logger(4, '%F %T')
local Enums = Discordia.enums
local Config = Json.decode(fs.readFileSync('config.json'))

local Token
if _G["dev"] then Token = getenv("BOT_DEVTOKEN") else Token = getenv("BOT_TOKEN") end

local insert,getn = table.insert,table.getn
local readFileSync,scanDirSync = fs.readFileSync,fs.scandirSync



local env = setmetatable({
	require = require,
	}, {__index = _G})


local function loadModules(path)
	local files = {}
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
				local code = assert(loadstring(data,n))
				setfenv(code,env)
				_G[n] = code()
				if _G[n].disabled then
					_G[n] = nil
				else
					_G[n].Deps = {Client = Client, Logger = Logger, Enums = Enums, Config = Config, Discordia = Discordia, Json = Json}
					_G[n]:__init()
				end
			end)
		if s then Logger:log(Enums.logLevel.info,"[Module] Loaded ".. n) else Logger:log(Enums.logLevel.error,"[Module] Failed to load " .. v .. " with error : \n" .. e) end 
	end
end


coroutine.wrap(function()
	if not Token then
		print("Unable to get token...")
		return false
	end
	loadModules("./modules")
	Commands:initCommands()

	Client:on("ready", Events.onReady)
	Client:on("messageCreate", Events.onMessage)
	Client:on("reactionAdd", Events.onReact)
	Client:on("reactionAddUncached", Events.onReact)
	Client:run('Bot '..Token)
end)()
