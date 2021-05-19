local wrap, running, resume, create, yield, status = coroutine.wrap, coroutine.running, coroutine.resume, coroutine.create, coroutine.yield, coroutine.status
local insert, remove = table.insert, table.remove
local timer = require('timer')

local uv = nil


--[[
	Timer
		-> 1	Timeout		int
		-> 2	Repeating	bool
		-> 3	Callback		func
		-> 4	Cancel		bool
		Our own timer system runs on luvit's timers because... well, I didn't know it existed and I didn't want to not use it
		after finishing it. Bad news is we need to use luvit's loop to run its loop.

]]
local TimersDaemon = {
    timers = {},
    deadTimers = {},
    activeTimers = 0,
    gcTask = nil,
    shouldGC = false
}

function TimersDaemon:createTimer(timeout, repeating, callback)
	local id = #self.timers+1
	local timeout = timeout * 1000000 --NS TO MS
	if timeout <= 0 then timeout = 1 end
	local time = uv.hrtime()
    if repeating then 
        self.timers[id] = {time + timeout, timeout, callback, false, time, cancel = function(self) self[4] = true end }
    else
        self.timers[id] = {time + timeout, 0, callback, false, time, cancel = function(self) self[4] = true end }
    end
	self.activeTimers = self.activeTimers + 1
	return self.timers[id]
end

function TimersDaemon:markDead(id)
    insert(self.deadTimers, id)
end

function TimersDaemon:cancelTimer(id)
    self:markDead(id)
	self.shouldGC = true
	Events.Deps.Logger:_info("Task finished ->" .. id)
end

function TimersDaemon:garbageCollect()
    if #self.deadTimers <= 0 then return end
    local deadTimers = Utils.instanceOf(self.deadTimers)
    self.deadTimers = {}
    if not deadTimers then return nil end
    return create(function()
		for _,v in ipairs(deadTimers) do
            remove(self.timers, v)
            self.activeTimers = self.activeTimers - 1
            yield()
        end
        deadTimers = nil
        return true
    end)
end

function TimersDaemon:init()
    self:createTimer(1000, false, function() end)
end

function TimersDaemon:stopAll()
    for k,v in ipairs(self.timers) do
        self:cancelTimer(k)
    end
end

function TimersDaemon:run()
    return create(function()
        while true do
            if self.gcTask then
                if status(self.gcTask) ~= "dead" then resume(self.gcTask) else self.gcTask = nil end
            end
            if self.activeTimers <= 0 then self.ends = true 
            else
                local time = uv.hrtime()
				for id,v in ipairs(self.timers) do
					if v[4] then self:cancelTimer(id) 
						Events.Deps.Logger:_error("Task " .. id .. " cancelled.")
					else
						if v[1] <= time  then
							local s,e = pcall(function() v[3](id) end)
							if not s then Events.Deps.Logger:_error("Task " .. id .. " failed to run with error " .. e) self:cancelTimer(id) end
							if v[2] == 0 then
								self:cancelTimer(id)
							else
								v[1] = time + v[2]
								v[5] = time
							end
						end
					end
                end
            end
            if self.shouldGC then if not self.gcTask then self.gcTask = self:garbageCollect() self.shouldGC = false collectgarbage() end end
            if self.ends then return end
            yield()
        end
    end)
end

local Events = {
	name = "Events",
	magicalCharacters = {'+','-','*','.','?','^','@',"#"},
	pendent = {
		guildLoad = {}
	},
	timersDaemon = nil
}

local function EndsWith(str1, str2)
	return str == "" or str1:sub(-#str2) == str2
end

function Events.onMessage(msg)

	--Check if its a command, if it is then attempt to run it
	if msg.author.bot then return end
	if Studios:getActiveStudio(msg.author.id) then Studios:callback(msg.author.id, msg.content) return end
	if not msg.guild then msg:reply("Excuse me sir, but I'm not employed to do private affairs!") return false end
	local prefix = Events.prefix
	local st = msg.content:find(Events.prefix)
	if st ~= 1 then 
		return 
	else
		local args = {}
		for k in msg.content:gmatch("%g+") do
			insert(args,k)
		end
		args.msg = msg


		for _,v in ipairs(Events.magicalCharacters) do
			if EndsWith(prefix,v) then
				prefix = prefix:gsub("%"..v,"%%"..v) -- Ugly stuff here, we check if it ends with a magical character and 
				break
			end
		end

		local s,e = Commands:Run(remove(args,1):gsub(prefix,""),args,msg)
	end
end

function Events.onReady()
	print("Starting events daemon")
	Events.ready = true
	Events:RunTimerDaemon()
	Events.Deps.Bot.readyModules()
end

function Events:RunTimerDaemon()
	if self.timer then return false end
	timer.setInterval(1, function() 
		if self.timersDaemon then
			if status(self.timersDaemon.thread) ~= "dead" then
				local s,e = pcall(function() resume(self.timersDaemon.thread) end)
				if not s then self.Deps.Logger:_error("Errored while trying to resume timer daemon.") end
			else
				self.Deps.Logger:_info("Event daemon died.")
				self.timersDaemon = nil
				collectgarbage()
			end
		end
	end)
	self.timer = true
end

function Events:createTimer(timeout, repeating, callback) --Timeout in MS
	if not self.ready then return false end
	if not self.timersDaemon then 
		self.timersDaemon = {handler = Utils.instanceOf(TimersDaemon)}
	end
	local id = self.timersDaemon.handler:createTimer(timeout, repeating, callback)
	if not self.timersDaemon.thread then self.timersDaemon.thread = self.timersDaemon.handler:run() end
	self.Deps.Logger:_info("Created task with timeout %d and repeating %s", timeout, tostring(repeating))
	return id
end

function Events:cancelTimer(id)
	if not self.timersDaemon then return false end
	self.timersDaemon.handler:cancelTimer(id)
	return true
end
	

function Events:__init()
	if not _G.dev then
		self.prefix = self.Deps.Config.Defaults.Prefix
	else
		self.prefix = self.Deps.Config.Defaults.DevPrefix
	end
	uv = self.Deps.Commons.uv
	return Events
end


return Events