--[[
	Timer
		-> 1	NextFinish	int
        -> 2    Period	    int
		-> 3	Callback	func
		-> 4	Cancel		bool

]]
local wrap, running, resume, create, yield, status = coroutine.wrap, coroutine.running, coroutine.resume, coroutine.create, coroutine.yield, coroutine.status
local insert, remove = table.insert, table.remove
local Utils = require('./modules/Utils')
local uv = require('uv')
Profiler = {}

function Profiler:start(name)
	return {name = name, sTime = uv.hrtime(), stop = function(self) return uv.hrtime() - self.sTime end}
end

local failure = 0
local threshold = 1000000


local TimersDaemon = {
    timers = {},
    deadTimers = {},
    activeTimers = 0,
    gcTask = nil,
    shouldGC = false
}

function TimersDaemon:createTimer(timeout, repeating, callback)
    local id = #self.timers+1
    local time = uv.hrtime()
    local timeout = timeout * 1000000
    if repeating then 
        self.timers[id] = {time + timeout , timeout, callback, false, time}
    else
        self.timers[id] = {time + timeout , 0, callback, false, time}
    end
    self.activeTimers = self.activeTimers + 1
	return id
end

function TimersDaemon:markDead(id)
    insert(self.deadTimers, id)
end

function TimersDaemon:cancelTimer(id)
    self.timers[id][4] = true
    self:markDead(id)
    self.shouldGC = true
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
                if v[1] <= time and not v[4] then
                    if time - v[1] >= threshold then failure = failure + 1 threshold = threshold * 10 end
                    v[3]()
                    if v[2] == 0 then
                        self:cancelTimer(id)
                    else
                        v[1] = time + v[2]
                        v[5] = time
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

local daemon = Utils.instanceOf(TimersDaemon)
math.randomseed(os.time())

local thread = daemon:run()
while true do
    if status(thread) ~= "dead" then
        resume(thread)
    else
        thread = nil
        collectgarbage()
        break
    end
end