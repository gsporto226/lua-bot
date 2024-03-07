local getenv = require('os').getenv
local json = require('json')
local p = require('pretty-print').prettyPrint
local http = require('coro-http')
local cprocess = require("childprocess")
local uv = require("uv")
local url = require('url')
local parseQuery = require('querystring').parse

local wrap,running,resume,yield = coroutine.wrap,coroutine.running,coroutine.resume,coroutine.yield
local insert,getn = table.insert,table.getn


local YoutubeHelper = {
	name = "YoutubeHelper"
}

-- TODO: MOVE DURATION GET TO PLAYTIME OF SONG AND TITLE TOO! THIS WILL ENABLE US TO USE LESS DAILY REQUESTS


function YoutubeHelper:uglyFormat(duration)
	local hours = duration:match("(%d+)H") or 0
	local minutes = duration:match("(%d+)M") or 0
	local seconds = duration:match("(%d+)S") or 0
	hours = tostring(hours)
	minutes = tostring(minutes)
	seconds = tostring(seconds)
	if seconds:len() < 2 then seconds = "0"..seconds end
	if hours:len() < 2 then hours = "0"..hours end
	if minutes:len() < 2 then minutes = "0"..minutes end
	return(hours..":"..minutes..":"..seconds)
end

function YoutubeHelper:parseUrl(url,searchString,playlist)
	if not self.DEVKEY then error("ERROR: Youtube Module could not be loaded!") end

	--local videoid = url:match("v=[%w_-]+")
	--local playlistid = url:match("list=[%w_-]+")
	local vTable = {} -- INDEX , VIDEOID
	--print("Parsing")
			
	if videoid and not playlist then --Play video only
		--Request Title and Duration
		videoid = videoid:gsub('v=',"")
		insert(vTable,videoid)
	end
	if playlistid and playlist then -- Playlist
		playlistid = playlistid:gsub('list=',"")
		print("Is playlist! " ..playlistid)
		local obj = self:request("https://www.googleapis.com/youtube/v3/playlistItems?&key="..self.DEVKEY.."&playlistId="..playlistid.."&fields=items(snippet(resourceId(videoId)))&part=snippet&maxResults=30")
		if obj and not obj.error then
			if obj.items then
				for _,v in ipairs(obj.items) do
					insert(vTable,v.snippet.resourceId.videoId)
				end
			end
		else error("Could not look up playlist, invalid id!") end
	end
	
	if not videoid and not playlistid then
		print("We search now "..searchString)
		local obj = self:request("https://www.googleapis.com/youtube/v3/search?&key="..self.DEVKEY.."&fields=items(id(videoId))&part=id&maxResults=1&q="..searchString.."&type=video")
		if obj and not obj.error and obj.items[1] then
				insert(vTable,obj.items[1].id.videoId)
				print("Inserted "..vTable[#vTable])
		else error("Could not search for ".. searchString) end
	end
	--yield()
	return vTable
end

function YoutubeHelper:request(url)
	local ojb
	local thread = running()
	wrap(function()
		local res,obj = http.request("GET", url)
		ojb = json.decode(obj)
		if res.code ~= 200 then if not ojb.error then obj.error = true return assert(resume(thread)) end end
		return assert(resume(thread))
		end)()
	yield()
	return ojb
end



--Deprecated!
function YoutubeHelper:getMusicId(args)
	if not args[1] then error("You need to specify an url or a text to search for!") end
	local url = args[1]
	local searchString

	local possibleArguments = {
		playlist = false
	}	

	for _,v in ipairs(args) do
		if possibleArguments[v:lower()] == false then
			possibleArguments[v:lower()] = true
		else
			if searchString then searchString = searchString .."+".. v else searchString = v end
		end
	end

	local parsedUrl = self:parseUrl(url,searchString,possibleArguments.playlist)
	return parsedUrl
end

--Takes youtube video ID and returns the video`s title and duration, deprecated
function YoutubeHelper:getInfoFromId(id)
	if not id then error("You need to provide an ID!") end
	local obj = self:request("https://www.googleapis.com/youtube/v3/videos?&key="..self.DEVKEY.."&id="..id.."&fields=items(snippet(title),contentDetails(duration))&part=snippet,contentDetails")
	if obj and not obj.error and obj.items[1] then
		return {id=id,title = obj.items[1].snippet.title, duration = obj.items[1].contentDetails.duration}
	else return false end
end


function YoutubeHelper:searchYoutubeVideo(string)
	local obj = self:request("https://www.googleapis.com/youtube/v3/search?&key="..self.DEVKEY.."&fields=items(id(videoId))&part=id&maxResults=1&q="..string.."&type=video")
	if obj and not obj.error and obj.items[1] then
		return obj.items[1].id.videoId
	else
		return nil
	end
end

function YoutubeHelper:getPlaylist(id)
	local playlistId = id
	local items = {}
	local pageToken = nil
	local res
	repeat
		if pageToken then
			res = self:request("https://youtube.googleapis.com/youtube/v3/playlistItems?key=" .. self.DEVKEY .. "&playlistId=" .. playlistId .. "&maxResults=50&fields=nextPageToken,items(snippet(resourceId(videoId)))&part=snippet&pageToken=" .. pageToken)
		else
			res = self:request("https://youtube.googleapis.com/youtube/v3/playlistItems?key=" .. self.DEVKEY .. "&playlistId=" .. playlistId .. "&maxResults=50&fields=nextPageToken,items(snippet(resourceId(videoId)))&part=snippet")
		end
		if res then
			if res.items then
				for _, id in ipairs(res.items) do
					table.insert(items, id.snippet.resourceId.videoId)
				end
			end
			if res.nextPageToken then
				pageToken = res.nextPageToken
			else
				pageToken = nil
			end
		else
			break
		end
	until not pageToken
	return items
end

function YoutubeHelper:getURL(string)
	local url = string:match("https*://[^%s]+")
	local youtube_string = "https://www.youtube.com/watch?v="
	local info = nil
	if not url then
		local searchString = self:searchYoutubeVideo(string)
		if searchString then
			youtube_string = youtube_string .. searchString
		else
			return false
		end
	else youtube_string = url end
	return youtube_string
end


function YoutubeHelper:getPlaylistId(string)
	local url = url.parse(string)
	if url and string.find(url.host, 'youtube') and url.query then
		local params = parseQuery(url.query)
		if params and params.list then
			return params.list
		end
	end
	return nil
end

function YoutubeHelper:videoUrlFromId(id)
	return "https://www.youtube.com/watch?v="..id
end

--Takes string literals as arguments, extracts URL or SEACH STRING, grabs information if it can find a valid VIDEO or SONG and stores it on the OBJECT.
function YoutubeHelper:getInfoFromURL(string, object)
	local thread = running()
	local stderr = uv.new_pipe(false)
	info = nil
	wrap(function()
			local process = uv.spawn("youtube-dl",{args={'--no-warnings','-i','--skip-download','--dump-json',string,'-o','-'},stdio={0,1,stderr}, function()
				assert(resume(thread))
			end},
			function()
				stderr:read_start(
				function(err,chunk)
					if err or not chunk then
					elseif chunk then
						info = json.decode(chunk)
						return assert(resume(thread))
					else
						return assert(resume(thread))
					end
				end)
			end
	)end)()
	yield()	
		--[[print("Process created ", process)
		process.stderr:on('data',function(data)
			print("Data on information process!")
			if data ~= nil then
				info = json.decode(data)
				if info ~= nil then
					assert(resume(thread))
				end
			end
		end)
	end)()
	yield()--]]
	return info
end

function YoutubeHelper:__init()
	self.DEVKEY = getenv("YOUTUBE_KEY")
	if not self.DEVKEY then return error("Could not load Module [YoutubeHelper], missing API KEY!") end
	return self
end





return YoutubeHelper
