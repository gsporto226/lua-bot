function round(number)
	if number%2 ~= 0.5 then
		return math.floor(number+0.5)
	end
	return number-0.5
end

print(((126%3600/60)-round(126%3600/60))*60)