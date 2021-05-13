local PlayerChances = {}
local Players = {}
local Distribution = {}
local RDistribution = {}
local lastSelected = 0
local repeatedCount = 0
local oldID = 0

local function SelectSpy(MaxNumber)
	math.randomseed(os.clock())
	local rng = math.random(1,MaxNumber)
	return math.ceil(rng/(MaxNumber/#Players))
end

local function AddPlayer()
	Players[oldID] = {Name="Player #"..oldID, timesRow = 1}
	oldID = oldID + 1
end

for i=0,22 do
	AddPlayer()
end

local tries = 0
local selected = ''
local maxNumber = 1000

while tries < 1000 do
	local s = nil
	local allowPass = false


	s = SelectSpy(maxNumber)
	if s == lastSelected then
		if repeatedCount >= 2 then
			repeat 
				s = SelectSpy(maxNumber)
			until s ~= lastSelected
			repeatedCount = 0
		elseif repeatedCount == 1 then
			s = SelectSpy(maxNumber)
			if s == lastSelected then
				repeatedCount = repeatedCount + 1
				if RDistribution[s] then RDistribution[s] = RDistribution[s] + 1 else RDistribution[s] = 1 end
			end
		else
			repeatedCount = repeatedCount + 1
			if RDistribution[s] then RDistribution[s] = RDistribution[s] + 1 else RDistribution[s] = 1 end
		end
	end
	if Distribution[s] then Distribution[s] = Distribution[s] + 1 else Distribution[s] = 1 end

	if selected ~= '' then selected = selected .. "|" ..  s else selected = s end
	lastSelected = s
	tries = tries + 1
end

for p,v in pairs(Distribution) do
	print(p .. " was selected " .. v .. " times")
end

for p,v in pairs(RDistribution) do
	print(p .. " was selected " .. v .." times in a row")
end

print(selected)