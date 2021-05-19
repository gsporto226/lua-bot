local insert = table.insert

local defaultGuildConfig = {
    prefix = "+",
}

local defaultUserConfig = {
    language = "us"
}

local Module = {
    path = "",
    relativeUsers = "users/",
    relativeGuilds = "guilds/",
    name = "Configs"
}

function Module:loadUserConfigJson(user) 
    local coroutine = coroutine
    local path = self.path..self.relativeUsers..user..".json"
    Utils:createIfNotExists(path)
    local result = self.Deps.Commons.fs.readFileSync(path)
    if not result then self:defaultUser(user) return self:loadUserConfigJson(user) end
    return self.Deps.Json.decode(result)
end

function Module:loadGuildConfigJson(guild)
    local coroutine = coroutine
    local path = self.path..self.relativeGuilds..guild..".json"
    Utils:createIfNotExists(path)
    local result = self.Deps.Commons.fs.readFile(path)
    if not result then self:defaultGuild(guild) return self:loadGuildConfigJson(guild) end
    return self.Deps.Json.denode(result)
end

function Module:saveGuildConfig(guild, config)
    if not config or type(config) ~= "table" then return false end
    local path = self.path..self.relativeGuilds..guild..".json"
    Utils:createIfNotExists(path)
    local encoded = self.Deps.Json.encode(config) or self.Deps.Json.encode({})
    self.Deps.Commons.fs.writeFileSync(path, encoded)
end

function Module:setGuildProperty(guild, key, value)
    local cfg = self:loadGuildConfigJson(guild)
    cfg[key] = value
    self:saveGuildConfig(guild, cfg)
    return true
end

function Module:saveUserConfig(user, config)
    if not config or type(config) ~= "table" then return false end
    local path = self.path..self.relativeUsers..user..".json"
    Utils:createIfNotExists(path)
    local encoded = self.Deps.Json.encode(config) or self.Deps.Json.encode({})
    self.Deps.Commons.fs.writeFileSync(path, encoded)
end

function Module:setUserProperty(user, key, value)
    local cfg = self:loadGuildConfigJson(user)
    cfg[key] = value
    self:saveUserConfig(user, cfg)
    return true
end

function Module:defaultGuild(guild)
    self:saveGuildConfigConfig(guild, defaultGuildConfig)
end

function Module:defaultUser(user)
    self:saveUserConfig(user, defaultUserConfig)
end

function Module:__init()
    self.path = self.Deps.Config.Defaults.ConfigFolder or ""
    if self.path == "" then
        self.Deps.Logger.log(self.Deps.Enums.logLevel.info, "[Config] Could not find default path string in configs.")
    end
end

function Module:__load()
end

return Module
