local getenv = require('os').getenv


--TODO: REDO MUSIC UPDATE LOOP ITS TOO CONFUSING

local wrap,running,resume,yield = coroutine.wrap, coroutine.running,coroutine.resume,coroutine.yield

local Music = {
	name = "Music"
}



local insert,remove = table.insert,table.remove
--[[Music object = {title,url,requester,textchannel}]]
--[[Queue = { index, musobject}]]

function Music.addToQueue(self,args,requester,textchannel,voiceChannel)
	--FIRST WE SEE IF ITS A VALID URL OR SEARCH REQUEST THEN WE PUT IT IN THE QUEUE!

	--Search for Arguments, remove them from the argument table and return a string literal
	local literal = nil

	local possibleArguments = {
		playlist = false
	}	

	for _,v in ipairs(args) do
		if possibleArguments[v:lower()] == false then
			possibleArguments[v:lower()] = true
		else
			if literal then literal = literal .."+".. v else literal = v end
		end
	end
	if possibleArguments.playlist then
		return false, "Playlists are nor supported atm."
	end

	--Create a placeholder sound object
	local soundObject = {url=nil,id=nil,title=nil,duration=nil,requester=requester,textchannel=textchannel,voicechannel=voiceChannel}
	soundObject.url = YoutubeHelper:getURL(literal)
	if not soundObject.url then print("F") return false, "Unable to find any media." end
	insert(self._queue,soundObject)
	if not self._currentlyPlaying then
		self._currentlyPlaying = (remove(self._queue,1))
		self:update()
	end
	local info = YoutubeHelper:getInfoFromURL(soundObject.url,soundObject)

	if info then
		soundObject.title = info.title
		soundObject.duration = info.duration
		soundObject.id = info.id
		soundObject.thumbnail = info.thumbnail
	end
	
	if soundObject.infoNeedsBroadcast then
		soundObject.textchannel:send{embed = Response.embeds.youtube.nowPlaying(soundObject)}
	else
		soundObject.textchannel:send{embed = Response.embeds.youtube.addedList(soundObject, 1)}--Temporarily only handles single musics
	end
	return true
	--[[if args[1]:find("soundcloud") then 
		insert(self._queue,{id=args[1],title="Soundcloud song",duration = ":)",requester=requester,textchannel=textchannel,voicechannel = voiceChannel}) 			
		if not self._currentlyPlaying then 
			self._currentlyPlaying = (remove(self._queue,1))
			self:update()
		end
 		return true
 	end

	local infoMessage
	local obj = YoutubeHelper:getMusicId(args)
	if not obj or not obj[1] then return false, "Invalid url or search" end

	local thread = running()
	wrap(function()
		for k,v in ipairs(obj) do

			local temp = YoutubeHelper:getInfoFromId(v)

			if not temp then insert(self._queue,{id=v,requester = requester,textchannel = textchannel, voicechannel =voiceChannel})
			else insert(self._queue,{id=temp.id,title=temp.title,duration=YoutubeHelper:uglyFormat(temp.duration),requester = requester,textchannel = textchannel, voicechannel =voiceChannel}) end
			
			if not infoMessage then infoMessage = textchannel:send{embed = Response.embeds.youtube.addedList(self._queue[#self._queue], k)}
			else infoMessage:setEmbed(Response.embeds.youtube.addedList(self._queue[#self._queue], k)) end
			
			if not self._currentlyPlaying then 
				self._currentlyPlaying = (remove(self._queue,1))
				self:update()
			end
		end
	end)()
	return true--]]
end

function Music:stop()
	local s = true
	local e 
	wrap(function()
		if not self._currentlyPlaying then s = false e = "There is nothing to stop" return 
		else 
			self._queue = {}
			self._currentlyPlaying = nil
			if self._connection then 
				self._connection:stopStream()
				self._connection = nil
			end
		end
	end)()
	return s,e
end

function Music:skip()
	if not self._currentlyPlaying then return false, "There is nothing to skip"
	else
		self._connection:stopStream()
	end
	return true
end

function Music:warn(string,info)
	if not info then 
		Logger:log(enums.logLevel.warning,("[Music] "..string))
	else
		Logger:log(enums.logLevel.debug, ("[Music] "..string))
	end
end

function Music:__init()
	self._ytHelper = YoutubeHelper
	self._queue = {}
	self._currentlyPlaying = nil
	self._history = {}
	self._connection = nil
	self.DEVKEY = getenv("YOUTUBE_KEY")
	return Music
end

function Music:update(eos)
	--Check if there is a music queued to play right now
	--if not eos then eos = false end
wrap(function()
	if eos then
		insert(self._history,self._currentlyPlaying)
		self._currentlyPlaying = remove(self._queue,1)
		if not self._currentlyPlaying then 
			if self._connection then
				self._connection:close() 
				self._connection = nil 
			end
			return false, "Queue is empty, closing connections!"
		else
			self:update()
		end
	else
		if self._currentlyPlaying then
			if not self._connection then
				self._connection = self._currentlyPlaying.voicechannel:join()
				self:update()
			else
				if self._history[#self._history] then
					if not self._currentlyPlaying.voicechannel.id == self._history[#self._history].voicechannel.id then
						self._connection:close()
						self._connection = self._currentlyPlaying.voicechannel:join()
					end
				end
				if self._currentlyPlaying.title and self._currentlyPlaying.duration then 
					self._currentlyPlaying.textchannel:send{embed = Response.embeds.youtube.nowPlaying(self._currentlyPlaying)}
				else
					self._currentlyPlaying.infoNeedsBroadcast = true
				end
				self._connection:playYoutube(self._currentlyPlaying.url)
				self:update(true)
			end
		else
			self:update(true)
		end
	end
end)()
end

return Music