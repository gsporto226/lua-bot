--COMMAND TEMPLATE
local Object = {
	name = "Command",
	usage = "No use, its just a template and should be disabled",
	cmdNames = {'command','template'},
    subcommands = {},
	disabled = true
}

local REASONS = {
	SUBCMD_DOES_NOT_EXIST = function(name) return 'Subcomando ' .. name .. ' não existe' end,
    SUBCMD_ARGUMENT_COUNT_MISMATCH = function(n) 
        local n = n or '(_DEU_RUIM_)'
        return 'Esperava-se ' .. n .. ' argumentos.' 
    end,
	EXAMPLE_ERROR = 'ERROR'
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
	-- Subcommand call
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
	-- Subcommand end
	return true
end

function Object:__init()
    self:addSubcommand('example', function(args, rawarg) 
        return true, REASONS.EXAMPLE_ERROR
    end)
end

return Object