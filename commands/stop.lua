
local p = require('pretty-print').prettyPrint


local Object = {
	name = "Stop",
	usage = "Stop the song!",
	cmdNames = {'stop'},
	dependsOnMod = "YoutubeHelper"
}


function Object.callback(self,args,rawarg)
	if self.dependsOnMod then if not _G[self.dependsOnMod] then error("Youtube module not loaded, play command is disabled!") end end
	return Music:stop()
end

function Object:__init()
end

return Object