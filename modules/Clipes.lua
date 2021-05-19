--[[

Pasta com clipes

aliases ->
    alias -> clipObj
clipObject ->
    freq -> int
    filename -> string

--]]
local resume, running, yield, wrap = coroutine.resume, coroutine.running, coroutine.yield, coroutine.wrap

local Module = {
    name = "Clipes",
    clipsRecordFile = "clipsRecord.json",
    fileExtension = ".ogg",
    guilds = {}
}

function Module:__load()
    Utils:createIfNotExists(self.path)
    local path = ""
    wrap(function()
        for guild,v in self.Deps.Commons.fs.scandirSync(self.path) do
            local path = self.Deps.Commons.path.join(self.path, guild)
            if not self.guilds[guild] then self.guilds[guild] = {
                aliased = {},
                unaliased = {}
            } end
            --No record file found, scan directory and create guild object
            for files, v in self.Deps.Commons.fs.scandirSync(path) do
                if not string.find(files, ".json") then
                    self.guilds[guild].unaliased[files] = true
                end
            end
            if self.Deps.Commons.fs.existsSync(self.Deps.Commons.path.join(path,self.clipsRecordFile)) then
                --Process record file and generate guild object
                local file = self:loadRecordFile(guild)
                if not file then return end
                for filename, clip in pairs(file) do
                    self:buildClipObject(guild, filename, clip)
                end
                file = nil
                collectgarbage()
            end
        end
    end)()
end

function Module:buildClipObject(guild, filename, clip)
    local clipObject = {freq = clip.freq, file = filename}
    for _, alias in ipairs(clip.aliases) do
        self.guilds[guild].aliased[alias] = clipObject
    end
    if self.guilds[guild].unaliased[filename] then self.guilds[guild].unaliased[filename] = nil collectgarbage() end
end

function Module:addAlias(guild, clipname, alias, title, duration)
    local title = title or "unnamed"
    local duration = duration or -1
    if self.guilds[guild] then
        if self.guilds[guild].unaliased[clipname..self.fileExtension] then
            self:buildClipObject(guild, clipname..self.fileExtension, {freq = 0, aliases = {alias}, title = title, duration = duration})
            self:saveRecordFile(guild)
            return true, "Alias " .. alias .. " adicionada ao clipe "
        else
            local file = self:loadRecordFile(guild)
            if not file then return false, "Não existe um arquivo de clipe com o nome " end
            if not file[clipname] then return false, "Clipes", "Não existe um arquivo de clipe com o nome " end
            local clipobj = file[clipname]
            table.insert(clipobj.aliases, alias)
            self:buildClipObject(guild, clipname..self.fileExtension, clipobj)
            self:saveRecordFile(guild)
            return true, "Alias " .. alias .. " adicionada ao clipe "
        end
    end
end

function Module:initializeGuildDirectory(guild)
    return Utils:createIfNotExists(self.path .. guild .. "/")
end

function Module:loadRecordFile(guild)
    local file
    local thread = running()
    wrap(function()
        self.Deps.Commons.fs.readFile(self.Deps.Commons.path.join(self.path, guild, self.clipsRecordFile), function(err, buffer)
            if not err then file = self.Deps.Json.decode(buffer) else file = false end
            assert(resume(thread))
        end)
    end)()
    yield()
    return file
end

function Module:saveRecordFile(guild)
    local recordFile = {}
    if not guild then return false end
    for alias, clipObj in pairs(self.guilds[guild].aliases) do
        if recordFile[clipObj.file] then
            table.insert(recordFile[clipObj.file].aliases, alias)
        else
            recordFile[clipObj.file] = {freq = clipObj.freq, aliases = {alias}}
        end
    end
    local path = self.Deps.Commons.path.join(self.path, guild, self.clipsRecordFile)
    Utils:createIfNotExists(path)
    self.Deps.Commons.fs.writeFileSync(path, self.Deps.Json.encode(recordFile))
    recordFile = nil
    collectgarbage()
end

function Module:listUnaliased(guild)
    if self.guilds[guild] then
        return self.guilds[guild].unaliased
    end
    return false
end

function Module:listAliased(guild)
    if self.guilds[guild] then
        return self.guilds[guild].aliased
    end
    return false
end

function Module:getByAlias(guild, alias)
    if self.guilds[guild] then
        if self.guilds[guild].aliased[alias] then
            return self.path .. guild .. "/" .. self.guilds[guild].aliased[alias].file
        end
    end
end

function Module:__init()
    self.path = self.Deps.Config.Defaults.ClipsFolder or ""
    if self.path == "" then return false, "Clips path not set in config" end
end

return Module
