string = '-p https://www.youtube.com/watch?v=bG1w8JkcPUo'

string = string:match("https*://[^%s]+")

print(string, string:len())