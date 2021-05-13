Profiler = {lol=0}


function Profiler:start()
	return setmetatable({stop = function() return os.clock()-sTime end},{__call = function() sTime = os.clock() end })
end

function Profiler:sleep(a)
	local t = os.clock()
	while os.clock() < t+a do
		print(os.clock().." " .. t+a)
	end
end
--MODIFY THE USELESS SHIT ASDASDASD

function Profiler:__init()
end

return Profiler
