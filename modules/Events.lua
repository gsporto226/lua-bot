local insert,getn,remove = table.insert,table.getn,table.remove
local p = require('pretty-print').prettyPrint


local Events = {
	name = "Events",
	magicalCharacters = {'+','-','*','.','?','^','@',"#"},
	registeredEvents = 
	{
		Emoji = {}
	},
	pendent = {
		guildLoad = {}
	}
}

local function EndsWith(str1, str2)
	return str == "" or str1:sub(-#str2) == str2
end

function Events.onMessage(msg)

	--Check if its a command, if it is then attempt to run it
	if msg.author.bot then return end
	if not msg.guild then msg:reply("Excuse me sir, but I'm not employed to do private affairs!") return false end
	local prefix = Events.prefix
	local st = msg.content:find(Events.prefix)
	if st ~= 1 then 
		return 
	else
		local args = {}
		for k in msg.content:gmatch("%g+") do
			insert(args,k)
		end
		args.msg = msg


		for _,v in ipairs(Events.magicalCharacters) do
			if EndsWith(prefix,v) then
				prefix = prefix:gsub("%"..v,"%%"..v) -- Ugly stuff here, we check if it ends with a magical character and 
				break
			end
		end

		local s,e = Commands:Run(remove(args,1):gsub(prefix,""),args,msg)
	end
end

function Events.onReady()
	print("Ready!")
end

function Events.onReact(...)
	local args = {...}
	if args[3] then
		Events:callBack("Emoji",args[3],{hash=args[3],msgId=args[2],userId = args[4]})
	else
		Events:callBack("Emoji",args[1].emojiName,{hash=args[1].emojiName,msgId=args[1].message.id,userId=args[2]})
	end
end

function Events:registerEvent(eventType,eventKey,callback)
	if not self.registeredEvents[eventType] then return false end
	if not self.registeredEvents[eventType][eventKey] then
		self.registeredEvents[eventType][eventKey] = {}
	end
	insert(self.registeredEvents[eventType][eventKey],callback)
end

function Events:callBack(eventType,eventKey,args)
	for k,v in pairs(self.registeredEvents) do
		if k == eventType then
			if not v[eventKey] then print("Key is not registered!") return false end
			for _,z in ipairs(v[eventKey]) do
				z(args)
			end
			break
		end
	end
end

function Events:__init()
	if not _G.dev then
		self.prefix = self.Deps.Config.Defaults.Prefix
	else
		self.prefix = self.Deps.Config.Defaults.DevPrefix
	end
	return Events
end


return Events