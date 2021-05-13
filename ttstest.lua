local json = require('json')
local http = require('coro-http')
local p = require('pretty-print').prettyPrint
local yield,wrap,resume,running = coroutine.yield,coroutine.wrap,coroutine.resume,coroutine.running

function request(url)
    local headers = {{"Content-Type","application/json"}, {"Accepts", "application/json"}}
    local body = {voice = "Ricardo", text = "Esta casa está ladrilhada, quem a desenladrilhará? O desenladrilhador. O desenladrilhador que a desenladrilhar, bom desenladrilhador será!"}
    body = json.stringify(body)
	local res,obj = http.request("POST", url, headers, body)
	if res.code ~= 200 then
        print("error")
        p(res)
    else
        p(res)
		for k,v in pairs(json.decode(obj)) do
			print(k,v)
		end
	end
end

wrap(function() 
	request("https://us-central1-sunlit-context-217400.cloudfunctions.net/streamlabs-tts")
end)()


