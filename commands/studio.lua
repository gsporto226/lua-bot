--COMMAND TEMPLATE
local Object = {
	name = "Studio",
	usage = "Abre o modo estúdio desejado.",
	cmdNames = {'studio','std'},
}



function Object.callback(self,args,rawarg)
    if not args[1] then return false, "O comando requer pelo menos 1 argumento." end
    if args[1] == "listar" or args[1] == "list" then
        local msg = "Estúdios disponíveis:"
        if #Studios.studioTypes then msg = "Não há estúdios disponíveis."  args.msg:reply{embed = Response.embeds.invalidCommand(self.name, msg)} return true end
        for k,_ in pairs(Studios.studioTypes) do
            msg = msg .. " " .. k
        end
        args.msg:reply{embed = Response.embeds.successCommandCommand(self.name, msg)}
        return true
    end
    local s = Studios:setActiveStudio(args.msg.author.id, args[1], args.msg.guild.id)
    if s then
        args.msg:reply{embed = Response.embeds.successCommand(self.name, "Modo estúdio aberto.")}
    else
        return false, "O tipo de estúdio **" .. args[1] .. "** não existe."
    end
    return true
end

function Object:__init()
end

return Object