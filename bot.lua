local Discordia = require('discordia')
local fs = require('fs')
local joinPath = require('path')
local uv = require('uv')
local Json = require('json')
local getenv = require('os').getenv

--Global variables
_G["dev"] = getenv("BOT_ISDEV") == "true"
_G["GLOBAL_MAXMEM"] = tonumber(getenv("BOT_MAXMEM")) or 512 --In MBytes

local Client = Discordia.Client()
local Logger = Discordia.Logger(4, '%F %T')
local Enums = Discordia.enums
local Config = Json.decode(fs.readFileSync('config.json'))
local Commons = {fs = fs, path = joinPath, uv = uv}
local version = "1.0.0"
local Modules = {}

local Token = ""

if _G["dev"] then Token = getenv("BOT_DEVTOKEN") else Token = getenv("BOT_TOKEN") end

local insert,getn = table.insert,table.getn
local readFileSync,scanDirSync = fs.readFileSync,fs.scandirSync

Bot = {
	readyModules = function()
		for _,v in ipairs(Modules) do
			if v.__ready then
				v:__ready()
				if not v.name then Logger:log(Enums.logLevel.info,"[Module] Some module does not have name. ") 
				else
					Logger:log(Enums.logLevel.info,"[Module] Called Ready for module ".. v.name) 
				end	
			end
		end
	end
}

local env = setmetatable({
	require = require,
	}, {__index = _G})


local function initModules(path)
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
				local data = assert(readFileSync(joinPath.join(path,v)))
				local code = assert(loadstring(data,n))
				setfenv(code,env)
				_G[n] = code()
				if _G[n] then
					if _G[n].disabled then
						_G[n] = nil
					else
						_G[n].Deps = {Commons = Commons, Client = Client, Logger = Logger, Enums = Enums, Config = Config, Discordia = Discordia, Json = Json, Bot = Bot}
						_G[n]:__init()
						Modules[#Modules+1] = _G[n]
					end
				else
					Logger:log(Enums.logLevel.error,"[Module] Failed to load ".. n)
				end
			end)
		if s then Logger:log(Enums.logLevel.info,"[Module] Initialized ".. n) else Logger:log(Enums.logLevel.error,"[Module] Failed to initialize " .. v .. " with error : \n" .. e) end 
	end
end

local function loadModules()
	for _,v in ipairs(Modules) do
		if v.__load then
			v:__load()
			if not v.name then Logger:log(Enums.logLevel.info,"[Module] Some module does not have name. ") 
			else
				Logger:log(Enums.logLevel.info,"[Module] Loaded module ".. v.name) 
			end	
		end
	end
end

local function UpdateStuff()
	uv.spawn('pip3', {
		args = {'install','--upgrade','youtube-dl'},
		stdio = {0, 1, 2},
	}, function() print("Updated Youtube-dl!") end)
end


coroutine.wrap(function()
	UpdateStuff()
	initModules("./modules")
	loadModules()
	Commands:initCommands()
	Client:on("ready", Events.onReady)
	Client:on("messageCreate", Events.onMessage)
	Client:on("reactionAdd", Events.onReact)
	Client:on("reactionAddUncached", Events.onReact)
	Client:run('Bot '..Token)
	Logger:log(Enums.logLevel.info, "[Bot] Finished Loading. Version is " .. version)
end)()
