
local p = require('pretty-print').prettyPrint


local Object = {
	name = "Play",
	usage = "play url or a search for youtube music",
	cmdNames = {'play','ply','paly','plya','pley','p'},
	dependsOnMod = "YoutubeHelper"
}


function Object.callback(self,args,rawarg)
	if self.dependsOnMod then if not _G[self.dependsOnMod] then return false, "The Music module failed to load or was disabled" end end
	if not args[1] then return false, "Can't find url or search keys" end
	if not args.msg.member.voiceChannel then return false, "You're not in a voice channel inside this discord guild!" end
	return Music:addToQueue(args,args.msg.author,args.msg.channel,args.msg.member.voiceChannel, rawarg.guild.id)
end

function Object:__init()
end

return Object