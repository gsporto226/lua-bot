--COMMAND TEMPLATE
local Object = {
	name = "Queue",
	usage = "Shows the current Queue",
	cmdNames = {'queue','kiwi','Q','q'}
}



function Object.callback(self,args,rawarg)
	local i = 1 -- Page index
	local embed=Response.embeds.youtube.queueList(Music:getGuild(rawarg.guild.id).queue, i)

	local msg = args.msg:reply{embed = embed} -- Msg object
	
	if not msg then return false,"Failed to created embed message!" end

	local addButton = function()
		msg:clearReactions()
		msg:addReaction('⬅')
		msg:addReaction('➡') -- Adding initial reactions
	end 
	addButton()

	Events:registerEvent("Emoji","➡", function(...)
		local args = {...}

		if not args[1].msgId == msg.id then return false end
		if Events.Deps.Client.user.id == args[1].userId then return false end



		if i*12 >= #Music:getGuild(args[1].guild.id).queue then addButton() print("Index is bigger than queue, queue is "..#Music:getGuild(args[1].guild.id).queue) end 
		i = i + 1
		local emb = Response.embeds.youtube.queueList(Music:getGuild(args[1].guild.id).queue,i)
		msg:setEmbed(emb)
		addButton()
		end)
	Events:registerEvent("Emoji","⬅", function(...)
		local args = {...}

		if not args[1].msgId == msg.id then return false end
		if Events.Deps.Client.user.id == args[1].userId then return false end

		if i <= 1 then addButton() return false end
		i = i - 1 
		local emb = Response.embeds.youtube.queueList(Music:getGuild(args[1].guild.id).queue,i)
		msg:setEmbed(emb)
		addButton()
		end)
	return true
end

function Object:__init()

end

return Object