
local uv = require('uv')

local ytProcessSuccess = false
local hrtime = uv.hrtime
local remove = table.remove
local unpack = string.unpack -- luacheck: ignore
local rep = string.rep
local yield, resume, running,wrap = coroutine.yield, coroutine.resume, coroutine.running, coroutine.wrap

local function onExit() 

end
local function onYTSucc()

end

local fmt = setmetatable({}, {
	__index = function(self, n)
		self[n] = '<' .. rep('i2', n)
		return self[n]
	end
})

local YoutubeProcess = require('class')('YoutubeProcess')

function YoutubeProcess:__init(url)
	self._stdout = uv.new_pipe(false)
	self._ytstdou = uv.new_pipe(false)
	if(string.find(url,"bilibili")) then
		self._youtubeProcess = uv.spawn('youtube-dl', {
			args = {url,'-f','flv', '-o','-','-q'},
			stdio = {0, self._ytstdou, 2},
		}, onExit)
	else
		self._youtubeProcess = uv.spawn('youtube-dl', {
			args = {url,'-f','bestaudio', '-o','-','-q'},
			stdio = {0, self._ytstdou, 2},
		}, onExit)
	end

	self._ffmpegProcess = uv.spawn('ffmpeg', {
		args = {'-i', 'pipe:0', '-ar', '48000', '-ac', '2', '-f', 's16le', 'pipe:1','-loglevel','quiet'},
		stdio = {self._ytstdou, self._stdout, 2},
	}, onExit)

	self._buffer = ''

end


function YoutubeProcess:read(n)
	local buffer = self._buffer
	local stdout = self._stdout
	local bytes = n * 2

	if not self._eof and #buffer < bytes then
		local thread = running()		
		stdout:read_start(function(err, chunk)
			if err or not chunk then
				self._eof = true
				self:close()
				return assert(resume(thread))
			elseif #chunk > 0 then
				buffer = buffer .. chunk
			end
			if #buffer >= bytes then
				stdout:read_stop()
				return assert(resume(thread))
			end
		end)
		yield()
	end

	if #buffer >= bytes then
		self._buffer = buffer:sub(bytes + 1)
		local pcm = {unpack(fmt[n], buffer)}
		remove(pcm)
		return pcm
	end
end

function YoutubeProcess:close()
	self._ffmpegProcess:kill()
	self._youtubeProcess:kill()
	if not self._stdout:is_closing() then
		self._stdout:close()
	end
	if not self._ytstdou:is_closing() then
		self._ytstdou:close()
	end
end

return YoutubeProcess
