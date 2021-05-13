local json = require("json")
local fs = require("fs")
local childprocess = require("childprocess")
local file = nil
local finishedReading = false


local process = childprocess.spawn('youtube-dl',
	{'--no-warnings','-i','--skip-download','--dump-json','https://www.youtube.com/watch?v=7ayt4EWMc-c','-o','-'})


local function data3(chunk)
	print("Type of " .. type(chunk))
	print(chunk)
	if chunk then
		file = json.decode(chunk)
		if  file then
			print(file.id,file.title)
		end
	end
end

process.stdout:on('data',data3)

process.stderr:on('data',data3)
process.stderr:on('readable',data3)

process.stderr:on('exit',function() print("exit") end)

process:on('error', function(err) print("Errored \n") for k,v in pairs(err) do print(k,v) end end)