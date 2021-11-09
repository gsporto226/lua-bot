
local p = require('pretty-print').prettyPrint

local REASONS = {
    SUBCMD_DOES_NOT_EXIST = function(name) return 'Subcomando ' .. name .. ' não existe' end,
    SUBCMD_ARGUMENT_COUNT_MISMATCH = function(n) 
        local n = n or '(_DEU_RUIM_)'
        return 'Esperava-se ' .. n .. ' argumentos.' 
    end
}

local function igenerator(tab)
    local coro = coroutine.create(function()
        if tab and type(tab) == 'table' then
            for k,v in ipairs(tab) do
                coroutine.yield(k, v)
            end        
        end
    end)
    return function()
        if coroutine.status(coro) ~= "dead" then
            local result = {coroutine.resume(coro)}
            local success = table.remove(result, 1)
            if not success then
                return nil
            else
                return table.unpack(result)
            end
        else
            return nil
        end
    end
end

--COMMAND TEMPLATE
local Object = {
	name = "Poker Planner",
	usage = "Planning de sprints",
	cmdNames = {'ppoker', 'pp'},
	disabled = false,
    subcommands = {}
}

function Object:addSubcommand(name, callback, arguments)
    local arguments = arguments or 0
    self.subcommands[name] = { callback = callback, arguments = arguments }
end

function Object:getSubcommand(name)
    return self.subcommands[name]
end

function Object:getAvailableSubcommands()
    return ''
end

function Object:hasSubcommand(name)
    return self.subcommands[name] ~= nil
end

function Object:callSubcommand(name, args, rawarg, ...)
    if not self:hasSubcommand(name) then
        return false, REASONS.SUBCMD_DOES_NOT_EXIST(name)
    end
    local extraArgs = {...}
    local subcommand = self:getSubcommand(name)
    if subcommand.arguments ~= #extraArgs then
        return false, REASONS.SUBCMD_ARGUMENT_COUNT_MISMATCH(subcommand.arguments)
    else
        return subcommand.callback(args, rawarg, table.unpack(extraArgs))
    end
end

function Object.callback(self,args,rawarg)
    local gen = igenerator(args)
    local _, word = gen()
    while word do
        local subcommand = self:getSubcommand(word)
        if not subcommand then
            args.msg.channel:send(REASONS.SUBCMD_DOES_NOT_EXIST(word))
        else
            local extraArgs = {}
            for i=1, subcommand.arguments do
                local _, w = gen()
                table.insert(extraArgs, w)
            end
            local result, reason = self:callSubcommand(word, args, rawarg, table.unpack(extraArgs))
            if not result then
                args.msg.channel:send(reason)
            else
                args.msg.channel:send(reason)
            end
        end
        _, word = gen()
    end
	return true
end

function Object:__init()
    for _, v in ipairs(self.cmdNames) do
        Events:whitelistPrivateCommand(v)
    end
    self:addSubcommand('open', function(args, rawarg) 
        local Player = args.msg.author
        return PokerPlanner:Open(Player)
    end)
    self:addSubcommand('close', function(args, rawarg) 
        local PlayerID = args.msg.author.id
        return PokerPlanner:Close(PlayerID)
    end)
    self:addSubcommand('next', function(args, rawarg) 
        local PlayerID = args.msg.author.id
        return PokerPlanner:Next(PlayerID)
    end)
    self:addSubcommand('join', function(args, rawarg, id)
        local Player = args.msg.author
        return PokerPlanner:Join(id, Player)
    end, 1)
end

return Object