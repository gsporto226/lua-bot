local json = require('json')
local http = require('coro-http')
local yield,wrap,resume,running = coroutine.yield,coroutine.wrap,coroutine.resume,coroutine.running

function request(url)
	local res,obj = http.request("GET",url)
	if res.code ~= 200 then
		print("error")
	else
		for k,v in pairs(json.decode(obj).items[1]) do
			print(k,v)
		end
	end
end

wrap(function() 
	request("https://www.googleapis.com/youtube/v3/search?&key=".."".."&fields=items(id(videoId))&part=id&maxResults=1&q=".."Reol".."&type=video")
end)()


