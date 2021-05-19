Profiler = {}

function Profiler:start(name)
	return {name = name, sTime = self.Deps.Commons.uv.hrtime(), stop = function(self) print("[Profiler]" .. self.name .. " concluded in " .. (self.Deps.Commons.uv.hrtime() - self.sTime)/1000000 .. "ms") return end}
end

function Profiler:__init()
end

return Profiler
