local json
local config
local logger
local enums
local http = require('coro-http')
local yield,wrap,resume,running = coroutine.yield,coroutine.wrap,coroutine.resume,coroutine.running
local p = require('pretty-print').prettyPrint

local TTS = {
    request_url = "https://us-central1-sunlit-context-217400.cloudfunctions.net/streamlabs-tts",
    method = "POST",
}

local function request(voice, text)
    local headers = {{"Content-Type","application/json"}, {"Accepts", "application/json"}}
    local url = "https://us-central1-sunlit-context-217400.cloudfunctions.net/streamlabs-tts"
    local body = {voice = voice, text = text}
    body = json.stringify(body)
    local ojb = {}
    local thread = running()
    wrap(function()
    	local res,obj = http.request("POST", url, headers, body)
        if res.code ~= 200 then
            logger:log(enums.logLevel.warning, "TTS request did not get response code 200.")
            ojb.error = res.code
        else
            ojb = json.decode(obj)["speak_url"]
        end
        assert(resume(thread))
    end)()
    yield()
    p(ojb)
    return ojb
end


function TTS.request(args, voice, text, rawargs)
    if not args.msg.member.voiceChannel then return false, "You're not in a voice channel inside this discord guild!" end
    if text == "" then text = TTS.defaultts end
    local url = request(voice, text)
    if url.error then return false, ("TTS service returned error code " .. url.error) end
    if not url then return false, ("Was not able to fetch tts with voice " .. voice) end
    local arguments = {url}
	return Music:addToQueue(arguments, args.msg.author, args.msg.channel, args.msg.member.voiceChannel, rawargs.guild.id)
end

function TTS:__init()
    json = self.Deps.Json
    config = self.Deps.Config
    logger = self.Deps.Logger
    enums = self.Deps.Enums
    self.defaultts = config.Defaults.DefaultTTS
end

return TTS