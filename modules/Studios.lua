local Module = {
    activeStudios = {},
    studioTypes = {},
    timeLimit = 60 * 1000 * 1000000
}

--[[
    Estrutura:
    Fazer um studio generalizado aqui, onde para cada studio extra eu só tenha que adicionar callbacks em uma table.
    toma input e dependendo do contexto chama algum callback
    Studio = {
        activeContext = nil,
        defaultContext = nil,
        contextos = {
            contexto1 = {
                funcao1 = {desc = string, argumentos = int, callback = func}
            },
            compartilhado = {
                funcao1 = {desc = string, argumentos = int, callback = func}
            }
        }
    }
]]
local error = 0
local info = 1
local limit = 20

local Studio = {
    name = nil,
    user = nil,
    guild = nil,
    activeContext = "",
    defaultContext = "",
    contexts = {size = 1},
    aliases = {},
    replyType = {error=0,info=1},
    lastActivity = nil
}

local function sharedBack(self) 
    local s,e = self:setActiveContext(self.defaultContext)
    if s then self:reply(error, e) else self:reply(info, e) end
end

local function sharedExit(self)
    Module:exitStudio(self.user)
end

local function sharedChangeContext(self, contexto)
    local s,e = self:setActiveContext(contexto[1])
    print(s, e)
    if s then self:reply(error, e) else self:reply(info, e) end
end

local function sharedList(self) 
    local str = ""
    if self.contexts[self.activeContext] then
        for k,v in pairs(self.contexts[self.activeContext]) do 
            str = str .. "\n" .. k .. " : " .. v[1] 
        end
    end
    for k,v in pairs(self.contexts["shared"]) do 
        str = str .. "\n" .. k .. " : " .. v[1]
    end
    self:reply(info, str)
    return true
end

local function sharedContexts(self)
    local str = ""
    if self.contexts.size and self.contexts.size > 1 then
        for k,v in pairs(self.contexts) do
            if not (k == "size") then str = str .. "\n" .. k end
        end
    else str = "Não existem contextos disponíveis além do compartilhado." end
    self:reply(info, str)
    return true
end

local function sharedAliases(self, cmd)
    local fobj = self:getFunctionObject(cmd[1])
    if not fobj then 
        self:reply(error, "Comando %s não existe no contexto atual.", cmd[1])
        return false 
    end
    if #fobj[4] <= 0 then
        self:reply(info, "Comando %s não possui outros nomes/alias.", cmd[1])
        return true
    else
        local msg = "Aliases para o comando " .. cmd[1] .. ": "
        for _,v in ipairs(fobj[4]) do msg = msg .. " " .. v end
        self:reply(info, msg)
        return true
    end
    return false
end

function Studio:reply(type, msg, ...)
    if not self.user then return false, "There is no user." end
    if ... then
        msg = string.format(msg, ...)
    end
    if msg:len() > 0 then
        msg = "["..self.name.."]\n" .. msg
        if type == error then msg =  "**"..msg.."**" end
        if type == info then msg = "```" .. msg .. "```" end
        Module.Deps.Client:getUser(self.user):send(msg)
    else
        Module.Deps.Client:getUser(self.user):send("?")
    end
end

function Studio:exit()
    Utils.purge(self)
end

function Studio:getFunctionObject(name)
    if self.aliases[name] then name = self.aliases[name] end
    if self.contexts[self.activeContext] and self.contexts[self.activeContext][name] then return self.contexts[self.activeContext][name]
    elseif self.contexts["shared"][name] then return self.contexts["shared"][name]
    else return nil end
end

function Studio:addFunction(context, alias, desc, argc, callback, aliases)
    if not self.contexts[context] then return false, "Context does not exist." end
    if not self.contexts[context][alias] then 
        self.contexts[context][alias] = {desc, argc, callback, aliases or {}}
        if aliases then
            for _,v in ipairs(aliases) do self.aliases[v] = alias end
        end
        return true
    end
    return false, "Function already exists."
end

function Studio:addSharedFunction(alias, desc, argc, callback, aliases)
    return Studio:addFunction("shared", alias, desc, argc, callback, aliases)
end

function Studio:callback(msg, at) -- Proccess input
    self.lastActivity = Module.Deps.Commons.uv.hrtime()
    local at = at or 0
    if not msg then return false, "End of string" end
    local cmd = msg()
    at = at + 1
    if at >= limit then self:reply(error, "Usuário enviou muitos comandos. O máximo é " .. limit) end
    if not cmd then return false, "End of string" end
    local fobj = self:getFunctionObject(cmd)
    if fobj then
        local args = {}
        local index = 0
        while(index ~= fobj[2]) do
            local arg = msg()
            at = at + 1
            index = index + 1
            if index >= limit then self:reply(error, "Usuário enviou muitos argumentos. O máximo é " .. limit) return end
            if fobj[2] <= 0 then
                if not arg or arg == "|" then break end              
            end
            if arg == nil then
                --Lack of arguments.
                self:reply(error, "O comando %s espera %d argumentos, mas foram passados apenas %d", cmd, fobj[2], index - 1)
                return false, "Lacking arguments."
            end
            args[#args+1] = arg
        end
        fobj[3](self, args)
        return self:callback(msg, at)
    else
        --Command .. cmd .. does not exist, continuing to process msg.
        self:reply(error, "O comando %s não existe." , cmd)
        return self:callback(msg, at)
    end
end

function Studio:createNewContext(name)
    if not self.contexts[name] then self.contexts[name] = {} self.contexts.size = self.contexts.size + 1 return true end
    return false, "Context already exists."
end

function Studio:setActiveContext(name)
    if self.activeContext == name then return false, "O contexto dado já é o contexto ativo." end
    if self.contexts[name] then self.activeContext = name return true, "Contexto trocado!" end
    return false, "Não existe o contexto com o nome dado."
end

function Studio:setDefaultContext(name)
    if self.defaultContext == name then return false, "Context is already default context." end
    if self.contexts[name] then self.defaultContext = name return true end
    return false, "No context with given name."
end

function Module:newStudioType(name)
    if self.studioTypes[name] then return false end
    self.studioTypes[name] = Utils.instanceOf(Studio)
    self.studioTypes[name].name = name
    return self.studioTypes[name]
end

function Module:getActiveStudio(user)
    return self.activeStudios[user]
end

function Module:setActiveStudio(user, type, guild)
    if self.activeStudios[user] then return false, "User already in an active studio." end
    if not self.studioTypes[type] then return false, "Studio type does not exist." end
    self.activeStudios[user] = Utils.instanceOf(self.studioTypes[type])
    self.activeStudios[user].user = user
    self.activeStudios[user].guild = guild
    self.activeStudios[user].lastActivity = self.Deps.Commons.uv.hrtime()
    Events:createTimer(1000, true, function(id)
        if self.activeStudios[user] and self.Deps.Commons.uv.hrtime() - self.activeStudios[user].lastActivity >= self.timeLimit then
            self:exitStudio(user)
            Events:cancelTimer(id)
        end
    end)
    return true
end

function Module:callback(user, msg) --Message is the whole string.
    local studio = self:getActiveStudio(user)
    if studio then
        studio:callback(msg:gmatch("[^%s]+"))
    else
        return false, "User does not have an active studio."
    end
end

function Module:exitStudio(user)
    if not self.activeStudios[user] then return false, "User is not using a studio." end
    self.activeStudios[user]:exit()
    self.activeStudios[user] = nil
    return true
end

function Module:__init()
    Studio:createNewContext("shared")
    Studio:addSharedFunction("exit", "Sair do modo estúdio.", 0, sharedExit, {"sair"})
    Studio:addSharedFunction("back", "Volta para o contexto padrão.", 0, sharedBack, {"voltar"})
    Studio:addSharedFunction("list", "Lista os comandos disponíveis.", 0, sharedList, {"listar"})
    Studio:addSharedFunction("contexts", "Lista os contextos disponíveis.", 0, sharedContexts, {"contextos"})
    Studio:addSharedFunction("change", "Muda para o contexto dado. Toma 1 argumento: contexto", 1, sharedChangeContext, {"mudar"})
    Studio:addSharedFunction("aliases", "Lista os alias do comando dado. Toma 1 argumento: comando", 1, sharedAliases, {"alias", "nomes"})
end

return Module
