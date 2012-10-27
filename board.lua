-- Filename: board.lua
-- Author: Francisco Ari Josino Junior
-- Date: 2012-06-09

board = {}
board.matrix = {}
board.x = 0
board.y = 0
board.w = 384
board.h = 384
board.themeColor = {0,255,255,125}
function board.load()
	--inicializando a matriz
	for i=1,8 do
		board.matrix[i]={}
		for j=1,8 do
			board.matrix[i][j]={x = board.x + board.w/8*(j-1), --criando um objeto generico de quadrado que nem merece nome
								y=board.y + board.h/8*(i-1),
								w=board.w/8,
								h=board.h/8,
								hasPiece = false}
		end
	end
end

function board.getPositionByCoordinates(x,y)
	for i=1,#board.matrix do
		for j=1,#board.matrix[i] do
			if x == board.matrix[i][j].x and y == board.matrix[i][j].y then
				return board.matrix[i][j]
			end
		end
	end
	return nil
end

function board.draw()
local drawmode = ''
	for i=1,8 do
		for j=1,8 do
			integer,fract = math.modf((i+j)/2)
			if fract == 0 then --se a soma dos indices for par, pinte
				drawmode = 'fill'
			else
				drawmode = 'line'
			end
			love.graphics.setColor(board.themeColor)
			love.graphics.rectangle( drawmode, board.matrix[i][j].x, board.matrix[i][j].y, board.matrix[i][j].w, board.matrix[i][j].h )
			love.graphics.setColor(eGui.themeColor)
		end
	end

end