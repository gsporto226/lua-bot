local uv = require('uv')

--COMMAND TEMPLATE
local Object = {
	name = "Version",
	usage = "checks youtube-dl version",
	cmdNames = {'yversion'}
}
local stdout = nil


function onExit()
print("Finished reading")
stdout:read_start(function(err,chunk)
	if err or not chunk then
		return true
	elseif chunk then
		print(chunk)
	else
		print(err)
	end
end
)
end

function Object.callback(self,args,rawarg)
	stdout = uv.new_pipe(false)

	local testProcess = uv.spawn('youtube-dl', {
			args = {'--version'},
			stdio = {0, stdout, 2},
		}, onExit)
	return true
end

function Object:__init()
end

return Object