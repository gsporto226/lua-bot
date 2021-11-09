local discordia
local logger
local enums 
--We should handle all interactivities here aside from message receiving and handling!
--[[
	TODO:
	Handle reactions to messages and shit

--]]

local getn, insert = table.getn,table.insert

local Response = {
	name = "Response",
	embeds = 
	{
		pokerplanner = {
			voteSessionReport = function(session, voteSession)
				local sum = 0
				local participation = 0
				local embed = {
					title = "Relatório de votação",
					fields =  {}
				}
				for id, score in pairs(voteSession.votes) do
					sum = sum + score
					participation = participation + 1
					local user = session.users[id]
					if user then
						table.insert(embed.fields, {
							name = user.name,
							value = "**"..score.."**"
						})
					end
				end
				local mean = 0
				local percentage = 0
				local userCount = Utils.pcount(session.users)
				if userCount > 0 then
					percentage = participation / userCount
				end
				if participation ~= 0 then
					mean = sum / participation
				end
				embed.description =  string.format("Participação --  **%f**%%\nMédia dos scores -- **%f**", percentage * 100, mean)
				return embed
			end,
			closingSessionReport = function(session, voteSessions)
				local participants = {}
				local sumOfSums = 0
				local sumOfParticipations = 0
				local count = 0
				local embed = {
					title = "Relatório da sessão",
					fields =  {}
				}
				for _, voteSession in ipairs(voteSessions) do
					count = count + 1
					local sum = 0
					local participation = 0
					for id, score in pairs(voteSession.votes) do
						sum = sum + score
						participation = participation + 1
						local user = session.users[id]
						if user then
							if not participants[id] then
								participants[id] = {
									name = user.name,
									participation = 0,
									sum = 0
								}
							end
							participants[id].participation = participants[id].participation + 1
							participants[id].sum = participants[id].sum + score
						end
					end
					sumOfSums = sumOfSums + sum
					sumOfParticipations = sumOfParticipations + participation
				end
				local scoresMean = 0
				local participationsMean = 0
				if count ~= 0 then
					scoresMean = sumOfSums / count
					participationsMean = sumOfParticipations / count
				end
				embed.description = string.format('Média de scores: **%f**, Média de participação: **%f**%%', scoresMean , participationsMean * 100)
				for _, info in pairs(participants) do
					local mean = 0
					local percentage = 0
					if info.participation ~= 0 then
						mean = info.sum / info.participation
					end
					if count ~= 0 then
						percentage = info.participation / count
					end
					table.insert(embed.fields, {
						name = info.name,
						value = string.format('Participou de **%d**%% das votações.\nA média dos scores dados foi **%f**', percentage * 100, mean)
					})
				end
				return embed
			end,
		},
		spyfall = {
			--SPYFALL
			successFeedback = function(description)
				local embed = 
				{
					title = "*Spyfall*",
			  		color = 1,
			  		description = description,
			  		timestamp = discordia.Date():toISO('T', 'Z'),
			  		footer = 
			  		{
			  			icon_url = "https://is5-ssl.mzstatic.com/image/thumb/Purple114/v4/f5/be/32/f5be324a-17b4-b0ce-2e54-aa6f6cb31184/AppIcon-0-1x_U007emarketing-0-0-85-220-0-7.png/246x0w.jpg",
			  			text = "Shhh"
			  		}
				}
				logger:log(enums.logLevel.debug, "Spyfall successful feedback embed")
				return embed
			end,
			failFeedback = function(description)
				local embed = 
				{
					title = "*Spyfail*",
			  		color = 1,
			  		description = description,
			  		timestamp = discordia.Date():toISO('T', 'Z'),
			  		footer = 
			  		{
			  			icon_url = "https://is5-ssl.mzstatic.com/image/thumb/Purple114/v4/f5/be/32/f5be324a-17b4-b0ce-2e54-aa6f6cb31184/AppIcon-0-1x_U007emarketing-0-0-85-220-0-7.png/246x0w.jpg",
			  			text = "x.x"
			  		}
				}
				logger:log(enums.logLevel.debug, "Spyfall unsuccessful feedback embed")
				return embed
			end
		},
		keyValueList = function(title,list)
			local embed = 
			{
	   			title = title,
	    		color = discordia.Color.fromRGB(114, 137, 218).value,
	    		fields = {},
	    		timestamp = discordia.Date():toISO('T', 'Z')
	  		}
	  		for k,v in pairs(list) do
				insert(embed.fields,{name=k, value = v})
			end
			logger:log(enums.logLevel.debug, "Key value list embed")
	  		return embed
	  	end,
	  	invalidCommand = function(name, error)
		  	local embed = 
		  	{
		  		title = "Command " .. name .. "  failed ",
		  		color = 16711680,
		  		description = error,
		  		timestamp = discordia.Date():toISO('T', 'Z'),
		  		footer = 
		  		{
		  			icon_url = "https://wow.zamimg.com/images/wow/icons/large/ability_vanish.jpg",
		  			text = "D:"
		  		}
			  }
			  logger:log(enums.logLevel.debug, "Invalid command embed")
		  	return embed
		end,
	  	youtube = 
		{
			nowPlaying = function(musicObject)
				if musicObject.duration then musicObject.duration =  Utils.formatFromSeconds(musicObject.duration) else musicObject.duration = "missingno" end
				local embed = 
				{
					title = "Now playing",
					thumbnail = {url = musicObject.thumbnail},
					color = discordia.Color.fromRGB(248,54,42).value,
					fields = {{name = musicObject.title, value = musicObject.duration, inline = true}},
					timestamp = discordia.Date():toISO('T','Z')
				}
				if not embed.thumbnail.url then
					embed['thumbnail'] = nil
				end
				logger:log(enums.logLevel.debug, "Music Now playing embed")
				return embed
			end,
			addedList = function (musicObject, total)
				if musicObject.duration then musicObject.duration =  Utils.formatFromSeconds(musicObject.duration) else musicObject.duration = "missingno" end
				musicObject.title = musicObject.title or "(ERROR)"
				musicObject.thumbnail = musicObject.thumbnail or "https://en.meming.world/images/en/thumb/2/2c/Surprised_Pikachu_HD.jpg/248px-Surprised_Pikachu_HD.jpg"
				local embed = 
				{
					title = "Music added to queue",
					thumbnail = {url = musicObject.thumbnail},
					color = 1873944,
					fields = {{name = musicObject.title, value = musicObject.duration, inline = true}},
					timestamp = discordia.Date():toISO('T','Z'),
					footer = 
					{
						text = total .." music(s) added to queue." 
					}
				}
				if not embed.thumbnail.url then
					embed['thumbnail'] = nil
				end
				logger:log(enums.logLevel.debug, "Music added to list embed")
				return embed
			end,
			queueList = function(queue,index)
	  		local embed = 
	  		{
	  			title = "Current queue list",
	  			color = discordia.Color.fromRGB(248,54,42).value,
	  			fields = {},
	  			timestamp = discordia.Date():toISO('T','Z')
	  		}
	  		for k,v in ipairs(queue) do
	  			if k > index * 12 then break end
	  			if k > (index-1)*12  then 
	  				if v.title then
	  					insert(embed.fields,{name="#"..k, value = v.title})
	  				else
	  					insert(embed.fields,{name="#"..k, value = "Unable to get information on video"})
	  				end
	  			end
			  end
			  logger:log(enums.logLevel.debug, "Music queue list embed")
	  		return embed
	  	end
	  	},
		codeblocks =
		{
			luaBlock = function(string)
				logger:log(enums.logLevel.debug, "Code blocks Lua")
				return "```lua"..string.."```"
			end
		},
		tts = {
			voicelist = function(voices)
				local embed = 
				{
					title = "Voices Available",
					color = discordia.Color.fromRGB(248,54,42).value,
					description = "",
					timestamp = discordia.Date():toISO('T','Z')
				}
				for k,v in pairs(voices) do
					if (v) then
						embed.description = embed.description .. "**" .. k .. "**\n"
					end
				end
				if embed.description == "" then embed.description = "There are no voices available :(." end
				logger:log(enums.logLevel.debug, "TTS voice list embed")
				return embed
			end
		}
	}
}





function Response:__init()
	discordia = self.Deps.Discordia
	logger = self.Deps.Logger
	enums = self.Deps.Enums
	return Response
end



return Response