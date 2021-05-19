local wrap,running,resume,yield = coroutine.wrap, coroutine.running,coroutine.resume,coroutine.yield
local insert,remove = table.insert,table.remove

--[[
GUILD OBJECT
QUEUE TABLE OF SONGS
VOICECONNECTION GUILD VOICE CONNECTION OBJECT

SONG OBJECT
GUILDID
VCHANNEL ID
TITLE
DURATION
URL
FILEPATH
TEXTCHANNELID
REQUESTER

TODO
ERROR HANDLING AND USER REPLY
]]

local maxIdleTime = 30 * 1000 * 1000000 --edit the first number in seconds


local Voice = {
    name = "Voice",
    guilds = {}
}

local function playNext(self)
    local next = self.queue:next()
    if not next then return nil end
    Utils.pp(next)
    if next.voicechannelID ~= self.voicechannelID then
        Voice:changeVoiceChannel(next.guildID, next.voicechannelID)
    end
    if not self.voiceconnection then Voice.Deps.Logger:_error("[Voice]Guild attempted to play song without active voice connection!") return end
    if next.url then
        wrap(function()
            self.voiceconnection:playYoutube(next.url)
            self:playNext()
        end)()
    end
    if next.filepath then
        wrap(function()
            self.voiceconnection:playFFmpeg(next.filepath)
            self:playNext()
        end)()
    end
end

local function skip(self)
    self.voiceconnection:stopStream()
    self:playNext()
end

local function stop(self)
    self.voiceconnection:stopStream()
    self.queue:clear()
end

local function pause(self)
    if self.voiceconnection._paused then
        self.voiceconnection:resumeStream()
    else
        self.voiceconnection:pauseStream()
    end
end


function Voice:createSongObject(guildID, vchannelID, title,duration,tchannelID, requester, uri)
    local url = uri["url"]
    local filepath = uri["filepath"]
    if not url or not filepath then return nil end
    return {
        guildID = guildID,
        voicechannelID = vchannelID,
        title = title,
        duration = duration, 
        textchannel = tchannelID, 
        requester = requester,
        url = url,
        filepath = filepath
    }
end

function Voice:changeVoiceChannel(guild, voicechannelID)
    if not voicechannelID then return self.Deps.Logger:_error("[Voice]Attempted to initialize vchannel with nil id.") end
    self:checkIfGuildObjectExists(guild)
    if self.guilds[guild].voicechannelID ~= voicechannelID then
        self.guilds[guild].voicechannelID = voicechannelID
        self:establishVC(guild)
    end
end

function Voice:establishVC(guild)
    if self.guilds[guild].voiceconnection then self.voiceconnection:close() end
    local voiceChannel = self.Deps.Client:getChannel(self.guilds[guild].voicechannelID)
    if not voiceChannel then self.Deps.Logger:_error("[Voice]Could not establish voice connection for guild " .. guild) else
        self.guilds[guild].voiceconnection = voiceChannel:join()
    end
end

function Voice:createSongAndInsert(guild, vchannelID, title,duration,tchannelID, requester, uri)
    self:addToQueue(guild, self:createSongObject(guild, vchannelID, title, duration, tchannelID, requester, uri))
    local guildO = self.guilds[guild]
    if guildO then
        if not guildO.voiceconnection then
            guildO:playNext()
        else
            if guildO.voiceconnection_paused then return end
            if guildO.voiceconnection._stopped then
                guildO:playNext()
            end
        end
    end
end

function Voice:addToQueue(guild, song)
    self:checkIfGuildObjectExists(guild)
    if not song then return end -- Reply, could not add song to the queue!
    self.guilds[guild].queue:insert(song)
end

function Voice:checkIfGuildObjectExists(guild)
    if not self.guilds[guild] then self:createGuildObject(guild) end    
end

function Voice:createGuildObject(guild)
    local obj = {
        queue = Utils:newQueue(),
        voicechannelID = nil,
        voiceconnection = nil,
        idleTime = nil,
        playNext = playNext,
        skip = skip,
        stop = stop,
        pause = pause,
    }
    obj.timer = Events:createTimer(1000, true, function(id)
        if not obj then Voice.Deps.Logger:_error("[Voice]Forcibly removed timer that did not have a pointer.") Events:cancelTimer(id) return end
        local time = Voice.Deps.Commons.uv.hrtime()
        if obj.voiceconnection then
            if not obj.voiceconnection._speaking then  
                if not obj.idleTime  then obj.idleTime = time end   
                if (time - obj.idleTime) >= maxIdleTime then
                    Voice:removeGuildObject(guild)
                end
            else
                obj.idleTime = nil
            end
        else
            if not obj.idleTime then obj.idleTime = time end
        end
    end)
    self.guilds[guild] = obj
end

function Voice:removeGuildObject(guild)
    if self.guilds[guild] then 
        if self.guilds[guild].voiceconnection then
            self.guilds[guild].voiceconnection:close()
        end
        if self.guilds[guild].timer then self.guilds[guild].timer:cancel() end
        self.guilds[guild] = nil 
    collectgarbage() end
end

function Voice:__init()
end

return Voice