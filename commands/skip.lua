
local p = require('pretty-print').prettyPrint


local Object = {
	name = "Skip",
	usage = "Skip the song!",
	cmdNames = {'skip'},
	dependsOnMod = "YoutubeHelper"
}


function Object.callback(self,args,rawarg)
	if self.dependsOnMod then if not _G[self.dependsOnMod] then error("Youtube module not loaded, play command is disabled!") end end
	return Music:skip(rawarg.guild.id)
end

function Object:__init()
end

return Object