local string = "https://www.youtube.com/watch?list=RDxpVfcZ0ZcFM&v=asd88a_isad"
local uv = require('uv')

local time = os.clock()

local videoid = string:match("&?v=[%w_-]+")
local playlistid = string:match("&?list=[%w_-]+")

if videoid then print("Video id "..videoid) end
if playlistid then print("Playlist id "..playlistid) end

print(os.clock()-time)

--0.000002