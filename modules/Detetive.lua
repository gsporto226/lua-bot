--[[
THOUGHTS

A board vai ter tamanho definido por w,h.
Zonas definirao os quartos.
Posicao guardada no player (x,y)
Movimento sera testado de duas formas: Out of bounds( fora do board) ou Inside Zone. (Zonas podem deixar voce entrar ou nao).


]]
--[[
DATA STRUCTURES


BOARD:
int height
int width
table[zone] Zones


ZONE:
int height
int width
int x
int y
bool passable
portal Portal(If has)


PLAYER:
int x
int y
str CharacterName
int PlayerID
user UserObj
table[card] Cards

]]


local Detetive = {
	
}



function Detetive:__init()
end

return Detetive