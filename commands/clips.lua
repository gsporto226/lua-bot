--COMMAND TEMPLATE
local resume, running, yield, wrap = coroutine.resume, coroutine.running, coroutine.yield, coroutine.wrap

--Implementar CLIPAR e ver no que dár

local Object = {
	name = "Clipes",
	usage = "Soundboard de clipes.",
	cmdNames = {'sb','clipes','soundbox'},
	subCommands = {},
	disabled = true
}

local Studio = {								
	name = "Clipes",
	subCommands = {sair=0,clipar=0,inicializar=0, listar=1, adicionar=2, remover=2},
	mode = 0,
}

function Studio:sair(msg)
	Studios:setActiveStudio(msg.author.id, nil)
	self.replyMessage:setContent(Response.content.studioResponse(self.name, "Modo estúdio fechado."))
	collectgarbage()
end

function Studio:clipar()
	self.mode = 1
end

function Studio:inicializar(msg)
	if Clipes:initializeGuildDirectory(msg.guild.id) then
		self.replyMessage:setContent(Response.content.studioResponse(self.name, "Diretório inicializado!"))
	else
		self.replyMessage:setContent(Response.content.studioResponse(self.name, "O diretório já havia sido inicializado."))
	end
end

function Studio:adicionar(msg, args)
	local file = args[1]
	local alias = args[2]
	if not file then self.replyMessage:setContent(Response.content.studioResponse(self.name, "Faltou o nome do arquivo.")) return end
	if not alias then self.replyMessage:setContent(Response.content.studioResponse(self.name, "Faltou um alias.")) return end
	self.replyMessage:setContent(Response.content.studioResponse(self.name, "Tentando adicionar alias " .. alias .. " para " .. file))
	local f, reason = Clipes:addAlias(msg.guild.id, file, alias)
	if f then self.replyMessage:setContent(Response.content.studioResponse(self.name, "Sucesso:\n"..reason)) else
	self.replyMessage:setContent(Response.content.studioResponse(self.name, "Falha ao tentar adicionar alias, razão:\n"..reason)) end
end

function Studio:listar(msg, args)
	self.replyMessage:setContent(Response.content.studioResponse(Studio.name, "Preparando para listar clipes nomeados!"))
	--Construct clips object and then send it back
	if not self.Clipes then 
		self.Clipes = Object:buildClipes(msg.guild.id)
	end
	if self.Clipes.size > 0 then
		local response = "Clipes"
		for clip, aliases in pairs(self.Clipes) do
			if clip ~= "size" then response = response .. "\n" .. clip .. "\t aliases =" .. aliases end
		end
		self.replyMessage:setContent(Response.content.studioResponse(Studio.name, response))
	else
		self.replyMessage:setContent(Response.content.studioResponse(Studio.name, "Não existem clipes para esse servidor!"))
	end
end

Studio[1] = function(self, msg) --Clipar command handler
	local args =  msg.content:gmatch("%g+")
end

Studio[0] = function(self, msg) -- Default command handler
	local args =  msg.content:gmatch("%g+")
	local nextArg = ""
	repeat
		nextArg = args()
		if nextArg then
			if self.subCommands[nextArg] then
				local arg = {}
				if self.subCommands[nextArg] > 0 then
					for i=0, self.subCommands[nextArg] do
						arg[#arg+1] = args()
					end
				end
				self[nextArg](self, msg, arg)
			end
		end
	until not nextArg
end

function Studio:callback(msg)
	Studio[self.mode](self, msg)
	--Check if we ( the bot ) has permission to delete messages
	if msg.guild then
		if msg.guild.me:hasPermission(msg.channel, Clipes.Deps.Enums.permission.manageMessages) then
			msg:delete()
		end
	end
end

function Studio:init(msg)
	self.guild = msg.guild
	self.author = msg.author
	local s, userConfig = Configs:requestConfigJson(self.guild.id, self.author.id)
	if s then
		if userConfig.privateStudio then self.channel = self.author.getPrivateChannel() else self.channel = msg.channel end
	else
		self.channel = msg.channel
	end
	self.replyMessage = self.channel:send(Response.content.studioResponse(self.name, "Inicializando modo estúdio.\nConstruíndo objeto de clipes."))
	--Construct all available clips
	self.Clipes = Object:buildClipes(msg.guild.id)
	self.replyMessage:setContent(Response.content.studioResponse(self.name, "Modo estúdio pronto para ser utilizado.\n Digite ajuda para uma lista de comandos disponíveis."))
end

function Object:listar(msg)
	local rep = msg:reply(Response.content.studioResponse(Studio.name, "Preparando para listar clipes nomeados!"))
	--Construct clips object and then send it back
	local clipes = self:buildNamedClipes(msg.guild.id)
	if clipes.size > 0 then
		msg:reply{embed = Response.embeds.keyValueList("Lista de Clipes", clipes)}
	else
		rep:setContent(Response.content.studioResponse(Studio.name, "Não existem clipes nomeados para esse servidor!"))
	end
end

function Object:studio(msg)
	local studio = Studios:getActiveStudio(msg.author.id)
	if not studio then
		Studios:setActiveStudio(msg.author.id, Utils.instanceOf(Studio))
		studio = Studios:getActiveStudio(msg.author.id)
		msg:reply{embed = Response.embeds.successCommand(self.name, "Acionado modo estúdio, estúdio ativo agora é  " .. studio.name)}
		studio:init(msg)
	else
		msg:reply{embed = Response.embeds.invalidCommand(self.name, "Usuário já está com modo estúdio ativado!\nO estúdio ativo é " .. studio.name)}
	end
end

function Object:buildClipes(guildid)
	local clipes = {size = 0}
	local aliased = Clipes:listAliased(guildid)
	local unaliased = Clipes:listUnaliased(guildid)
	if aliased then
		wrap(function()
			for alias, clip in pairs(aliased) do
				if not clipes[clip.filename] then clipes[clip.filename] = alias end
				clipes[clip.filename] = clipes[clip.filename] .. " " .. alias
				clipes.size = clipes.size + 1
			end
		end)()
	end
	if unaliased then
		wrap(function()
			for _, clip in ipairs(unaliased) do
				if not clipes[clip] then clipes[clip] = "" end
				clipes.size = clipes.size + 1
			end
		end)()
	end
	return clipes
end

function Object:buildNamedClipes(guildid)
	local clipes = {size = 0}
	local aliased = Clipes:listAliased(guildid)
	if aliased then
		wrap(function()
			for alias, clip in pairs(aliased) do
				if not clipes[clip.file] then clipes[clip.file] = alias end
				clipes[clip.file] = clipes[clip.file] .. " " .. alias
				clipes.size = clipes.size + 1
			end
		end)()
	end
	return clipes
end

function Object:play(msg, alias)
	if not msg.member.voiceChannel then msg:reply{embed = Response.embeds.invalidCommand(self.name, "Você precisa estar numa sala de voz para usar esse comando.")}return end
	local clipObj = Clipes:getByAlias(msg.guild.id, alias)
	if not clipObj then msg:reply{embed = Response.embeds.invalidCommand(self.name, "Não existe clipe com o alias " .. alias .. ".")}return end
	Voice:createSongAndInsert(msg.guild.id, msg.member.voiceChannel.id, alias, -1, msg.channel.id, msg.author.name, {["filepath"] = clipObj})
end

function Object:callback(args,msg)
	local command = false
	for k, v in ipairs(args) do
		if self.subCommands[v] then
			self.subCommands[v](self, msg)
			command = true
		end
	end
	if not command then
		self:play(msg, args[2])
	end
	return true
end

function Object:__init()
	self.subCommands['listar'] = self.listar
	self.subCommands['list'] = self.listar
	self.subCommands['studio'] = self.studio
end

return Object


--Mas que caralho é essa merda mano, puta que pariu. Pensa num código bagunçado, mal feito e provavelmente infestado de
--bugs.