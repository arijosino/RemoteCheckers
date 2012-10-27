-- Filename: deadzone.lua
-- Author: Francisco Ari Josino Junior
-- Date: 2012-06-10

require 'board'

deadzone = {}
deadzone.x = 0
deadzone.y = 0
deadzone.w = board.w/2 --devera ter a largura de 2 colunas do tabuleiro
deadzone.h = board.h * 3/4

-- Initialization
function deadzone.load()
	local columnCounter = 0
	local rowCounter = 0
	for i=1,24 do
		deadzone[i] = {x = deadzone.x + (deadzone.h/6 * columnCounter),y = deadzone.y + (deadzone.h/6 * rowCounter),w = deadzone.w/4,h = deadzone.h/6,occupied = false}
		if columnCounter < 3 then
			columnCounter = columnCounter + 1
		else
			columnCounter = 0
			rowCounter = rowCounter + 1
		end
	end
	
end

-- Scene Drawing
function deadzone.draw()
	for i=1,#deadzone do
		love.graphics.rectangle( 'line', deadzone[i].x, deadzone[i].y, deadzone[i].w, deadzone[i].h )
	end
end