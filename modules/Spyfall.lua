local json
local fs = require('fs')
local joinPath = require('path').join

local readFileSync,scanDirSync = fs.readFileSync,fs.scandirSync

local Spyfall = {
	name = "Spyfall",
	Locations = {},
	lobbies = {},
	PlayerList = {},
	lobbiesCreated = 0,
	MaxRandomNumber = 1000,
	RepeatChance = 200,
	LocationCount = 0,
	seeded = false
}

--[[
Player List Player Data Structure
int playerID ISKEY
str LobbyName
]]

--[[
Lobby Data Structure
str Name ISKEY
int LeaderID
tabl[players] Players
tabl[int] PlayerNames
int PlayerCount
int CurrentSpy
str CurrentLocation
str LastLocation
int LocationRepeatCount
int CurrentRound
bool Running
str LastSpy
cfg Config
timer Timer
TextChannel FeedBackChat
]]

--[[
Player Data Structure
str Name ISKEY
int ID
bool IsSpy
str CurrentProfession
int TimesRow
user UserObj
]]

--[[
Location Data Structure
str Name
table[str] Professions
]]

function generateRandomNumber(MaxNumber, Max) --Generates random numbers up to #Players
	if not Spyfall.seeded then
		math.randomseed(os.clock())
		Spyfall.seeded = true
	end
	local rng = math.random(1,MaxNumber)
	return math.ceil(rng/(MaxNumber/Max))
end


--[[Player-Lobby Interactions]]


function Spyfall:ReturnLocations(User)
	local literal = ''
	for _,l in ipairs(self.Locations) do
		if literal then literal = literal .. "\n" .. l.name else literal = l.name end
	end
	User:send("```"..literal.."```")
	return true, "Sent to user."
end

function Spyfall:AddLobby(lobbyname, leaderid, leaderName, leaderUser, chat)
	local lobbyName = lobbyname or "Spyfall Lobby #" .. self.lobbiesCreated --If no lobby name is given we create it with a default name
	if self.lobbies[lobbyname] then
		return false, "Lobby with that name already exists"
	end
	self.lobbies[lobbyName] = {Name = lobbyName, LeaderID = leaderid, Players = {}, PlayerNames = {}, PlayerCount = 0 ,CurrentSpy = "None", CurrentLocation = "None", LastLocation = "None", LocationRepeatCount = 0,CurrentRound = 0,Running = false, Config = {Length = 12}, LastSpy = "None", Timer = nil, FeedBackChat = chat} -- Create Lobby Object
	self:PlayerJoin(leaderid, leaderName, lobbyName, leaderUser) --Put the lobby creator inside the lobby
	self.lobbiesCreated = self.lobbiesCreated + 1 -- Increase lobby count for default lobby name generation
	return self:Feedback(self.lobbies[lobbyName], false, "Lobby \"" .. lobbyName .. "\" created.")
end

function Spyfall:PlayerJoin(playerID, name, lobbyName, userObj)
	if not self.lobbies[lobbyName] then
		return false, "Lobby does not exist"
	end
	if self.PlayerList[playerID] then -- Check if the player is already registered.
		if self.PlayerList[playerID] == "None" then
			self.PlayerList[playerID] = lobbyName --If the player was already registered but is currently in no lobby
		else
			return false, "Player already in a lobby named " .. self.PlayerList[playerID] .. " if you want to leave the lobby please use sf leave"
		end
	else -- Register the player and put him in the lobby
		self.PlayerList[playerID] = lobbyName
	end
	self.lobbies[lobbyName].Players[name] = {Name = name, ID = playerID, IsSpy = false, CurrentProfession = "None", UserObj = userObj, TimesRow = 1} -- Create Player Object
	table.insert(self.lobbies[lobbyName].PlayerNames, name) --Insert player into PlayerNumber table.
	self.lobbies[lobbyName].PlayerCount = self.lobbies[lobbyName].PlayerCount + 1 --Increase player count
	return true, "Joined lobby \"" .. lobbyName .. "\" as " .. name
end

function Spyfall:PlayerLeave(playerID, playerName)
	if self.PlayerList[playerID] then --Check if this player is registered and which lobby he is in
		if self.lobbies[self.PlayerList[playerID]] then --Check if he is indeed in that lobby
			if self.lobbies[self.PlayerList[playerID]].Running then --Check if there is a round ongoing
				return false, "Cannot leave lobby while a game is ongoing"
			end
			local lobby = self.lobbies[self.PlayerList[playerID]]
			lobby.Players[playerName] = nil --Remove his player object from the Players
			lobby.PlayerCount = lobby.PlayerCount - 1 --Reduce from player count
			for k,v in ipairs(lobby.PlayerNames) do --Lua table.getn and # both don`t count KEYED elements, so we have to separately keep which playerNumber is which player.
				if v == playerName then
					table.remove(lobby.PlayerNames, k) --This removes their number from the possible numbers.
				end
			end
			if playerID == lobby.LeaderID and lobby.PlayerCount > 0 then
				lobby.LeaderID = lobby.Players[lobby.PlayerNames[1]].ID
				self:Feedback(lobby, false, "Lobby leader for " .. lobby.Name .. " is now " .. lobby.Players[lobby.PlayerNames[1]].Name)
			end
			local oldLobby = lobby.Name --Store the lobby`s name as we are going to remove it next line
			if lobby.PlayerCount <= 0 then
				lobby = nil
				print("Deleted lobby " .. oldLobby)
			end
			self.PlayerList[playerID] = "None" --Set Player`s lobby to default None
			return true, "Removed player " .. playerName .. " from lobby \"" .. oldLobby .."\"." --Send a msg notifying the user.
		end
	end
	return false, "Player is not in a lobby"
end

--Player-Lobby END

--[[
SELECTION METHODS
]]

function Spyfall:ClearSystem()
	self.PlayerList = {}
	self.lobbies = {}
	self.lobbiesCreated = 0
	return true, "Cleared lobbies."
end

function Spyfall:SelectSpy(lobby)
	local selectedNumber = nil
	local allowPass = false
	local lastSpy = lobby.LastSpy
	while not allowPass do --We loop until we get another spy or the spy is approved to repeat
		selectedNumber = generateRandomNumber(self.MaxRandomNumber, lobby.PlayerCount)
		selectedPlayerName = lobby.PlayerNames[selectedNumber]
		selectedPlayer = lobby.Players[selectedPlayerName]
		if selectedPlayer.Name == lastSpy then -- If the selected spy is a repeat we do a 2nd check to see if he is allowed to repeat
			selectedPlayer.TimesRow = selectedPlayer.TimesRow + 1
			math.randomseed(os.clock())
			if (math.random(1,100) < (self.RepeatChance/selectedPlayer.TimesRow)) then --The spy only repeats if this is true, the higher the Repeat Chance is the more frequent Spies repeat.
				allowPass = true
			end
			lastSpy = selectedPlayer.Name
		else
			if not lastSpy == "None" then
				lobby.Players[lastSpy].timesRow = 1 -- We reset the times in a row counter if last spy is not selected.
			end
			allowPass = true 
		end
	end
	return selectedPlayer
end

function Spyfall:SelectLocation(lobby)
	local loc = generateRandomNumber(self.MaxRandomNumber, self.LocationCount)
	if self.Locations[loc].name == lobby.LastLocation then
		if lobby.LocationRepeatCount >= 2 then
			repeat 
				loc = generateRandomNumber(self.MaxRandomNumber, self.LocationCount)
			until self.Locations[loc].name ~= lobby.LastLocation
			lobby.LocationRepeatCount = 0
		elseif lobby.LocationRepeatCount == 1 then
			 loc = generateRandomNumber(self.MaxRandomNumber, self.LocationCount)
			if loc == lobby.LastLocation then
				lobby.LocationRepeatCount = lobby.LocationRepeatCount + 1
			end
		else
			lobby.LocationRepeatCount = lobby.LocationRepeatCount + 1
		end
	end
	return loc
end

--SELECTION END

--[[
Lobby methods
]]

function Spyfall:Feedback(lobby, fail, description)
	if fail then
		lobby.FeedBackChat:send{embed = Response.embeds.spyfall.failFeedback(description)}
	else
		lobby.FeedBackChat:send{embed = Response.embeds.spyfall.successFeedback(description)}
	end
	return true,""
end

function Spyfall:TimeOutRound(lobby)
	local Timer = coroutine.create(
		function ()
		Spyfall.Deps.Client:waitFor("WillNeverHappen", ( lobby.Config.Length* 60 * 1000))
		Spyfall:LobbyEndRound(lobby)
		end
	)
	return Timer
end

function Spyfall:StartLobby(playerID, playerName)
	--Check if the player is in a lobby and if he is, if he is the leader.
	local lobby = nil
	if self.PlayerList[playerID] then
		if self.PlayerList[playerID] ~= "None" then
			lobby = self.lobbies[self.PlayerList[playerID]]
		end
	end

	if not lobby then
		return false, "Player not in lobby."
	end

	if lobby.LeaderID ~= playerID then
		return self:Feedback(lobby, true, "Only the leader can start a game!.")
		--return false, "Only the leader can start the game!"
	end
	-- Lobby is set, is it already running?
	if lobby.Running then
		return self:Feedback(lobby, true, "There is already an ongoing session!.")
		--return false, "There is already an ongoing session!"
	end

	if lobby.PlayerCount <= 1 then
		return self:Feedback(lobby, true, "Can not start a game with only 1 player.")
		--return false, "Can`t start game with only 1 player"
	end

	if self.LocationCount <= 0 then
		return self:Feedback(lobby, true, "There are no Locations configured, please contact the admin.")
		--return false, "There are no Locations configured, please contact the admin"
	end
	--Game start logic 
	lobby.CurrentRound = lobby.CurrentRound + 1
	lobby.Running = true
	--Spy selection and notification
	lobby.LastSpy = lobby.CurrentSpy
	lobby.CurrentSpy = self:SelectSpy(lobby).Name
	lobby.Players[lobby.CurrentSpy].IsSpy = true
	lobby.Players[lobby.CurrentSpy].CurrentProfession = "Spy"
	--Location selection
	lobby.LastLocation = lobby.CurrentLocation
	lobby.CurrentLocation = self:SelectLocation(lobby)
	local possibleProfessions = {table.unpack(self.Locations[lobby.CurrentLocation].roles)} -- Copy possible professions
	for player, obj in pairs(lobby.Players) do --Iterate players and assign them Professions and tell them the location.
		if not(player == lobby.CurrentSpy) then
			if not(#possibleProfessions > 0) then
				possibleProfessions = {table.unpack(self.Locations[lobby.CurrentLocation].roles)} --Copy again if we run out
			end
			local n = generateRandomNumber(self.MaxRandomNumber, #possibleProfessions)
			obj.CurrentProfession = possibleProfessions[n]
			table.remove(possibleProfessions, n)
			obj.UserObj:send("SPYFALL: Round " .. lobby.CurrentRound .. " starting.")
			obj.UserObj:send("SPYFALL: You are NOT the spy, the location is " .. string.upper(self.Locations[lobby.CurrentLocation].name) .. " and your profession is " .. string.upper(obj.CurrentProfession)) -- notify the player
		else
			obj.UserObj:send("SPYFALL: Round " .. lobby.CurrentRound .. " starting.")
			obj.UserObj:send("SPYFALL: You are the SPY. Good luck.")
		end
	end
	--First questioner selection
	local number = generateRandomNumber(self.MaxRandomNumber, lobby.PlayerCount)
	local name = lobby.PlayerNames[number]
	lobby.Timer = self:TimeOutRound(lobby)
	coroutine.resume(lobby.Timer)
	return self:Feedback(lobby, false, "The first person to ask a question is " .. name  .. ".\nGame started and will end in " .. lobby.Config.Length .. " minutes.")
end

function Spyfall:LobbyEndRound(lobby)
	lobby.Running = false
	lobby.CurrentSpy = "None"
	lobby.CurrentLocation = "None"
	lobby.Timer = nil
	for _,p in pairs(lobby.Players) do
		p.CurrentProfession = "None"
		p.isSpy = false
	end
	self:Feedback(lobby, false, "Game ended! Please Vote for who you think is the SPY and ask Leader to start next round when ready!")
	return self:Feedback(lobby, false, "Round ended! waiting for  next round!")
end

function Spyfall:EndRound(playerID)
	--Check if the player is in a lobby and if he is, if he is the leader.
	local lobby = nil
	if self.PlayerList[playerID] then
		if self.PlayerList[playerID] ~= "None" then
			lobby = self.lobbies[self.PlayerList[playerID]]
		end
	end

	if not lobby then
		return false, "Player not in lobby."
	end

	if lobby.LeaderID ~= playerID then
		return self:Feedback(lobby, true, "Only the leader can stop a round!")
	end

	if lobby.Running then
		lobby.Running = false
		lobby.CurrentSpy = "None"
		lobby.CurrentLocation = "None"
		coroutine.yield(lobby.Timer)
		lobby.Timer = nil
		for _,p in pairs(lobby.Players) do
			p.CurrentProfession = "None"
			p.isSpy = false
		end
		return self:Feedback(lobby, false, "Round end. Waiting to start another round!")
	else
		return self:Feedback(lobby, true, "No round is ongoing!")
	end
end

--Lobby END

function Spyfall:__init()
	--Read all Location JSON and register
	json = self.Deps.Json
	local files = {}
	local path = "./games/spyfall/locations"
	--Scan modules file in path
	for k,v in scanDirSync(path) do
		if not(k == "template.json") then
			if k:find('.json',-5) then
				table.insert(files,k)
			end
		end
	end
	for _,v in ipairs(files) do
		local loc = json.decode(readFileSync(joinPath(path,v)))
		if loc then
			table.insert(self.Locations,loc)
			self.LocationCount = self.LocationCount + 1
		end
	end
end

return Spyfall