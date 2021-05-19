local Overwrites = {
    name = "Overwrites"
}

function Overwrites:__init()
end

function Overwrites:__load()
    self.Deps.Logger._info = function(self, info, ...) self:log(3, info, ...) end
    self.Deps.Logger._error = function(self, error, ...) self:log(1, error, ...) end
end

return Overwrites
