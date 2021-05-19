--[[
    ITEM
    damage int
    healLife int 
    healMana int 
    consumable bool
    potion bool
    autoReuse bool
    reuseDelay int
    defense int
    ToolTip string
    rare int
    shoot int
    shootSpeed float
    lifeRegen int
    manaIncrease int
    mana int
    crit int
    material bool
    buffType int
    buffTime int
    noMeele bool
    value int
    social bool
    vanity bool
    melee bool
    magic bool
    ranged bool
    summon bool
    sentry bool
    questItem bool
    mech bool
    flame bool
    fishingPole int
    bait bool
    dye int
    expertOnly bool
    expert bool
    type int
    holdStyle int
    usesSyle int
    channel bool
    accessory bool
    useTime int
    useAnimation int
    maxStack int
    pick bool
    axe bool
    hammer bool
    knockBack float


    IMPLEMENTAR
    Pesquisar Por Tag
    Conlcuir pesquisa e apresentar ao usuário.
]]
local running, resume, yield = coroutine.running, coroutine.resume, coroutine.yield

local Modes = {
    subtract = 0,
    add = 1,
}

local Conditionals = {
    none = 0,
    moreThan = 1,
    lessThan = 2,
    equalTo = 3
}

local function filtrar(studio, strings)
    if not strings or #strings <= 0 then studio:reply(studio.replyType.error,"Não foram encontrados argumentos para com os quais fazer a busca.") end
    studio:reply(studio.replyType.info, "Inciando busca, aguarde.")
    local userConfig = Configs:loadUserConfigJson(studio.user)
    if not userConfig then studio:reply(studio.replyType.error, "Erro desconhecido ao tentar fazer busca.") return end
    if not Terraria.info[userConfig["language"]] then Terraria:loadLanguageIfNeeded(userConfig["language"]) end
    local lang = userConfig["language"]
    if not Terraria.sharedInfo then Terraria:loadSharedInfoIfNeeded() end
    if not studio.result then studio.result = Utils.Set() end
    if not studio.searched then studio.searched = {} end
    local index = 1
    while(index <= #strings) do
        local word = strings[index]
        local original = word
        local mod = word:sub(1,1)
        local mode = Modes.add
        local compare = Conditionals.none
        local compareTo = nil
        local searchByTag = nil
        local success = false
        if mod == "-" then word = word:sub(2) mode = Modes.subtract end
        local tags = Terraria.sharedInfo["availableTags"]
        if tags and tags[word] then
            searchByTag = word
            if tags[word] == "number" then
                local comparator = strings[index + 1]
                local compared = false
                if comparator == ">" then
                    compare = Conditionals.moreThan
                elseif comparator == "<" then
                    compare = Conditionals.lessThan
                elseif comparator == ">=" then
                    compare = Conditionals.moreThan+Conditionals.equalTo
                elseif comparator == "<=" then
                    compare = Conditionals.lessThan+Conditionals.equalTo
                elseif comparator == "==" then
                    compare = Conditionals.equalTo
                end
                if compared then
                    compareTo = tonumber(strings[index + 2])
                    index = index + 2
                end
            end
        end
        local temporary = nil
        if mode == Modes.subtract and studio.result.__size <= 0 then
            for k, _ in pairs(Terraria.sharedInfo["items"]) do
                if tonumber(k) then studio.result:insert(tonumber(k)) end                
            end
        end
        if searchByTag then
            --Implementar :))
        else
            if #word < 3 then studio:reply(studio.replyType.info, "Pesquisas por nome só podem ser feitas com pelo menos 3 caractéres.") return end
            if Terraria.info[lang] then
                temporary = Utils.Set{Terraria.info[lang]["mappedNames"][word]} or Utils.Set()
                for id, tooltip in pairs(Terraria.info[lang]["toolTips"]) do
                    if tooltip:find(word) then
                        temporary:insert(tonumber(id))
                    end
                end
                success = true
            end
        end
        if success then
            if mode == Modes.subtract then
                studio.result = studio.result - temporary
            else
                if studio.result.__size <= 0 then
                    studio.result = studio.result + temporary
                else
                    studio.result = studio.result * temporary
                end
            end
            studio.searched[original] = true
        end
        index = index + 1
    end
    studio:reply(studio.replyType.info, "A pesquisa agora tem %d resultados", studio.result.__size)
end


local Terraria = {
    name = "Terraria",
    loaded = false,
    validLangs = {us = true, br = true}, 
    defaultLang = "us",
    info = nil,-- Lang -> Table
    sharedInfo = nil, 
    TerrariaStudio = nil
}

function Terraria:getLangOrDefault(lang)
    return self.validLangs[lang] and lang or self.defaultLang
end

function Terraria:loadLanguageIfNeeded(lang)
    lang = self:getLangOrDefault(lang)
    print(lang)
    if not self.info[lang] then
        local path = self.relativeLang .. lang .. "/"
        if not self.Deps.Commons.fs.existsSync(path) then return false, "No language " .. lang .. " found." end
        self.info[lang] = {}
        for files, type in self.Deps.Commons.fs.scandirSync(path) do
            local name = files:gsub(".json", "")
            local loadedObject = self.Deps.Commons.fs.readFileSync(path..files)
            if loadedObject then loadedObject = self.Deps.Json.decode(loadedObject) end
            if loadedObject then 
                self.info[lang][name] = loadedObject
            else
                self.Deps.Logger:_error("Could not load file %s for language %s.", files, lang)
            end
        end
    end
end

function Terraria:loadSharedInfoIfNeeded()
    if not self.sharedInfo.loaded then
        --Load items info first
        self.sharedInfo["availableTags"] = {}
        for files,_ in self.Deps.Commons.fs.scandirSync(self.relativeItems) do
            local name = files:gsub(".json", "")
            local loadedObject = self.Deps.Commons.fs.readFileSync(self.relativeItems..files)
            if loadedObject then loadedObject = self.Deps.Json.decode(loadedObject) end
            if loadedObject then 
                for k, value in pairs(loadedObject) do
                    self.sharedInfo["availableTags"][name] = type(value) == "table" and "number" or "boolean"
                    break
                end
                self.sharedInfo[name] = loadedObject
            else
                self.Deps.Logger:_error("Could not load file %s for sharedItems", files)
            end
        end
        --Set stuff TBI
        self.sharedInfo.loaded = true
    end
end

function Terraria:__load()
    self.loaded = true
    if not self.info then self.info = SCTable:new() end
    if not self.sharedInfo then self.sharedInfo = SCTable:new() end
    self:loadSharedInfoIfNeeded()
    self.TerrariaStudio = Studios:newStudioType("terraria")
    self.TerrariaStudio:createNewContext("pesquisar")
    self.TerrariaStudio:setDefaultContext("pesquisar")
    self.TerrariaStudio:addFunction("pesquisar", "filtrar", "Filtra pelos argumentos dados. Não há limites fora os de quantidade de comando e argumento, que são 20 e 12, respectivamente.\nUso: filtrar tag/literal, se usar tag como filtro é possível usar comparação. Ex. filtrar damage > 10.\nAo resultado será adicionado itens com mais de 10 de dano.\nTambém é possível negar pesquisas adicionando - no ínicio, isso fará com que o resultado exclua tudo que bate com o que vem depois do -, seja tag ou literal.", -1, filtrar, {"filter"})
end

function Terraria:__ready()
end 

function Terraria:__init()
    self.path = self.Deps.Config.Defaults.TerrariaFolder or ""
    if self.path == "" then return false, "Clips path not set in config" end
    self.relativeItems = self.path .. "items/"
    self.relativeSets = self.path .. "sets/"
    self.relativeLang = self.path .. "lang/"
end

return Terraria
