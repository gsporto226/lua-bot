local TIMEOUT_MINUTES = 10
local TIMEOUT = 60 * 1000 * TIMEOUT_MINUTES
local VOTETIMEOUT_SECONDS = 3
local VOTE_TIMEOUT = 1000 * VOTETIMEOUT_SECONDS
local DEURUIM = '_DEU_RUIM_'

local Timer = require('timer')
local wrap = coroutine.wrap

local REASONS = {
	SESSION_DOES_NOT_EXIST = 'A sessão que você tentou se juntar não existe.',
	USER_ALREADY_IN_SESSION = 'Usuário já está nessa sessão.',
	USER_IS_OWNER = 'Usuário já possui sessão criada.',
	USER_IS_NOT_OWNER = 'Usuário não é o host de nenhuma sessão.',
	USER_IS_NOT_IN_SESSION = 'Usuário não está fazendo parte de nenhuma sessão.',
	USER_DOES_NOT_EXIST = 'Usuário não existe.',
	VOTING_SESSION_DOES_NOT_EXIST = 'Não há sessão de voto ativa.'
}

local ANSWERS = {
	CLEARED = 'Sessões limpadas com sucesso.',
	USER_REMOVED = function(sessionID)
		local sessionID = sessionID or DEURUIM
		return 'Você foi removido da sessão ' .. sessionID
	end,
	SESSION_CREATED = function(sessionID)
		return 'Sessão criada, para que outros usuários se juntem a ela peça que usem o comando `pp join ' .. sessionID .. '`'
	end,
	SESSION_CLOSED = 'Sessão encerrada com sucesso!',
	VOTESESSION_STARTING = 'Nova sessão de voto começou, digite um score.\nSequência de Fibbonacci 0 1 1 2 3 5 8 13 21 34 55 89 144 ...',
	SESSION_JOINED = 'Você se juntou à sessão com sucesso, digite um score.'
}

local PokerPlanner = {
	name = "PokerPlanner",
	sessions = {},
	users = {}
}

--[[
	Vote -> {
		indexed by id
		userName string
		score number
	}
]]

--[[
	USER
	indexed by id
	{
		name string,
		activeSession hostID
	}
    Session
	indexed by playerID
	owner playerID
	users users[]
	activeVoteSession = {
		votes = {},
		result = mean of votes
	}
    voteSessions = {
		history of voteSessions
	}
]]

local function createVoteSession()
	return {
		votes = {},
		result = 0
	}
end

local function createSession(playerID, msg)
	return {
		msg = msg,
		owner = playerID,
		users = {},
		activeVoteSession = createVoteSession(),
		voteSessions = {},
		resetTimer = nil,
		voteTimer = nil
	}
end

local function createUser(player)
	return {
		id = player.id,
		name = player.name,
		activeSession = nil,
		player = player
	}
end

function PokerPlanner:getUser(playerID)
	return self.users[playerID] or false
end

function PokerPlanner:addUser(player)
	if not self:getUser(player.id) then
		self.users[player.id] = createUser(player)
		return self.users[player.id]
	end
	return false
end

function PokerPlanner:removeUser(playerID)
	local user = self:getUser(playerID)
	if user then
		if user.activeSession then
			user.player:send(ANSWERS.USER_REMOVED(user.activeSession))
		end
		self.users[playerID] = nil
	end
end

function PokerPlanner:getSession(sessionID)
	return self.sessions[sessionID]
end

function PokerPlanner:closingSessionReport(sessionID)
	local session = self:getSession(sessionID)
	if not session then
		return false, REASONS.SESSION_DOES_NOT_EXIST
	end
	self:notifyAllPlayers(sessionID, {embed = Response.embeds.pokerplanner.closingSessionReport(session, session.voteSessions)})
end

function PokerPlanner:closeSession(sessionID)
	local session = self:getSession(sessionID)
	if session then
		self:closingSessionReport(sessionID)
		for id, _ in pairs(session.users) do
			self:removeUser(id)
		end
		self.sessions[sessionID] = nil
	end
end

function PokerPlanner:joinSession(sessionID, player)
	local session = PokerPlanner:getSession(sessionID)
	if not session then
		return false, REASONS.SESSION_DOES_NOT_EXIST
	end
	local user = PokerPlanner:getUser(player.id)
	if not user then
		user = PokerPlanner:addUser(player)
	end
	if session.users[player.id] then
		return false, REASONS.USER_ALREADY_IN_SESSION
	end
	user.activeSession = sessionID
	session.users[player.id] = user
	return true, ANSWERS.SESSION_JOINED
end

function PokerPlanner:leaveSession(sessionID, playerID)
	local session = self:getSession(sessionID)
	if session then
		local player = session.users[playerID]
		if player then
			session.users[player] = nil
			self:removeUser(playerID)
		end
	end
end

function PokerPlanner:notifyAllPlayers(sessionID, notification)
	local session = self:getSession(sessionID)
	if session then
		for _, user in pairs(session.users) do
			wrap(function()
				user.player:send(notification)
			end)()
		end
	end
end

function PokerPlanner:Next(playerID)
	local session = self:getSession(playerID)
	if not session then
		return false, REASONS.USER_IS_NOT_OWNER
	end
	self:clearVoteTimer(playerID)
	self:ResetTimer(playerID)
	local active = session.activeVoteSession
	if active then
		self:notifyAllPlayers(playerID, {embed = Response.embeds.pokerplanner.voteSessionReport(session, active)})
	end
	table.insert(session.voteSessions, active)
	session.activeVoteSession = createVoteSession()
	self:notifyAllPlayers(playerID, ANSWERS.VOTESESSION_STARTING)
end

function PokerPlanner:Open(player)
	if not self.sessions[player.id] then
		self:addUser(player)
		self.sessions[player.id] = createSession(player.id)
		local joined, reason = self:joinSession(player.id, player)
		if not joined then
			return joined, reason
		end
		self:ResetTimer(player.id)
		return true, ANSWERS.SESSION_CREATED(player.id)
	else 
		return false, REASONS.USER_IS_OWNER
	end
end

function PokerPlanner:Close(playerID)
	if not self.sessions[playerID] then
		return false, REASONS.USER_IS_NOT_OWNER
	else
		self:closeSession(playerID)
		return true, ANSWERS.SESSION_CLOSED
	end
end

function PokerPlanner:Join(sessionID, player)
	return self:joinSession(sessionID, player)
end

function PokerPlanner:clearVoteTimer(sessionID)
	local session = self:getSession(sessionID)
	if session.voteTimer then
		Timer.clearTimeout(session.voteTimer)
		session.voteTimer = nil
	end
end

function PokerPlanner:checkEveryoneVoted(session)
	self:clearVoteTimer(session.owner)
	local voted = true
	for id, _ in pairs(session.users) do
		if not session.activeVoteSession.votes[id] then
			voted = false
			break
		end
	end
	if voted then
		session.voteTimer = Timer.setTimeout(VOTE_TIMEOUT, function()
			self:Next(session.owner)
		end)
	end
end

function PokerPlanner:ClearSystem()
	self.users = {}
	self.sessions = {}
	return true, ANSWERS.CLEARED
end

function PokerPlanner:ResetTimer(sessionID)
	local session = self:getSession(sessionID)
	if session then
		if session.resetTimer then
			Timer.clearTimeout(session.resetTimer)
		end
		session.resetTimer = Timer.setTimeout(TIMEOUT, function()
			self:closeSession(sessionID)
		end)
	end
end

function PokerPlanner:userInput(player, input)
	local user = self:getUser(player.id)
	if not user then
		return false, player:send(REASONS.USER_DOES_NOT_EXIST)
	end
	local session = self:getSession(user.activeSession)
	if not session then
		return false, player:send(REASONS.USER_IS_NOT_IN_SESSION)
	end
	if not session.activeVoteSession then
		return false, player:send(REASONS.VOTING_SESSION_DOES_NOT_EXIST)
	end
	session.activeVoteSession.votes[user.id] = input
	self:checkEveryoneVoted(session)
end

--Lobby END

local function inspector(words)
	if not words.msg.author then
		return false
	end
	local id = words.msg.author.id
	local user = PokerPlanner:getUser(id)
	if not user then
		return false
	end
	if #words <= 0 then
		return false
	end
	local first = words[1]
	local number = nil
	if first then
		number = tonumber(first)
	end
	if not number then
		return false
	end
	return number, words.msg.author
end

local function consumer(number, player)
	PokerPlanner:userInput(player, number)
end

function PokerPlanner:__init()
	Events:registerRedirect(inspector, consumer)
end

return PokerPlanner