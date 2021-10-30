--COMMAND TEMPLATE
local Object= {}

local function checkVoice(args, index)
	voice = args[index]
	if not voice then Object.values.voz = Object.values.default_voz return end
	voice = voice:lower()
	local b = voice:sub(1,1)
	b = b:upper()
	voice = b .. voice:sub(2, voice:len())
	if Object.possibleVoices[voice] == true then
		Object.values.voz = voice
	else
		Object.values.voz = Object.values.default_voz
	end
end

local function listVoices(args, index)
	args.msg:reply{embed = Response.embeds.tts.voicelist(Object.possibleVoices)}
	return -1
end

Object = {
	name = "Text-To-Speak",
	usage = "Use a TTS service.",
	cmdNames = {'tts'},
	dependsOnMod = "TTS",
	possibleVoices = {
		Ricardo = true,
		Mizuki = true,
		Brian = true,
		Vitoria = true,
		Emma = true,
		Ivy = true,
		Ines = true,
		Cristiano = true
	},
	subCommands = {
		voz = checkVoice,
		voice = checkVoice,
		list = listVoices,
		listar = listVoices
	},
	values = {
		default_voz = "Ricardo",
		voz = "Ricardo"
	}
}

local function checkSubCommands(args)
	local i = 1
	Object.values.voz = Object.values.default_voz
	while (i <= #args) do
		if Object.subCommands[args[i]] then
			local r = Object.subCommands[args[i]](args, i+1)
			if r == -1 then return false end
			i = i + 2
		else
			i = i + 1
		end
	end
	return true
end

function Object.callback(self,args, rawarg)
	local string = args.msg.content:match('".+"')
	self.values.voz = self.values.default_voz
	if string then 
		string = string:sub(1, string:len() - 1)
		string = string:sub(2, string:len())
	else
		string = ""
	end
	if self.dependsOnMod then if not _G[self.dependsOnMod] then return false, "The Music module failed to load or was disabled" end end
	local procceed = checkSubCommands(args)
	if string and procceed then return TTS.request(args, self.values.voz, string, rawarg)
	else return true end
end

function Object:__init()
end

return Object