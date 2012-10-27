-- Filename: piece.lua
-- Author: Francisco Ari Josino Junior
-- Date: 2012-06-10
require 'board'
require 'teleport'
pieceArray = {} --vetor de peças de tamanho 24

defaultTeam1FillColor = {0,100,0,255}
defaultTeam1LineColor = {0,255,0,255}

defaultTeam2FillColor = {125,49,0,255}
defaultTeam2LineColor = {255,100,0,255}

kingshipLineColor = {255,255,0,255}

--numericos: x,y,rad e team(pode ser 1 ou 2)
--booleanos:selected,visible
Piece = {x,y,radius,team,fillColor,lineColor,selected,kingship,visible}
function Piece:new(objeto) --construtor padrão
	setmetatable(objeto,self)
	self.__index = self
	return objeto
end

-- Initialization
function Piece.load()
	local time = 1
	local cor = defaultTeam1FillColor--cor default baseada no tema do cliente
	local corLinha = defaultTeam1LineColor
	for i=1,8 do
		if i>=6 then
			time = 2
			cor = defaultTeam2FillColor --cor default baseada no tema do servidor
			corLinha = defaultTeam2LineColor
		end
		for j=1,8 do
			integer,fract = math.modf((i+j)/2)
			if fract == 0 and (i<=3 or i>=6) then --se o quadrado for pintado e for nos campos certos, coloque a peça
				table.insert(pieceArray,Piece:new({x=board.matrix[i][j].x+board.w/16,y=board.matrix[i][j].y+board.h/16,radius=board.w/16,team = time,fillColor = cor,lineColor = corLinha,selected = false,kingship = false,visible = true}))
				board.matrix[i][j].hasPiece=true
			end
		end
	end
	
end

-- Logic
function update(dt)

end

function Piece.mousepressed(x,y,btn)
	
	if btn == 'l' then
		if (board.x <= x and x <= board.x + board.w and
			board.y <= y and y <= board.y + board.h ) or 
			(deadzone.x <= x and x <= deadzone.x + deadzone.w and
				deadzone.y <= y and y <= deadzone.y + deadzone.h)then --se o usuario clicar dentro do morto ou do tabuleiro...
			--percorrendo o vetor de peças para verificar se o usuario clicou em alguma peça
			for k,v in ipairs(pieceArray) do
				if v.x - v.radius <= x and x <= v.x + v.radius and
				 v.y - v.radius <= y and y <= v.y + v.radius then
					if Piece.getSelectedPiece() == nil and v.team == myTeam and v.visible then --se não tiver clicado em nenhuma peça logo antes
						Piece.desselectAll() --desselecionando todas as peças e selecionando a atual
						v.selected = true
						addToLog('selecionou a peça' .. k)
					end
				end
			end
			--percorrendo a matriz do tabuleiro para verificar se o usuario clicou em uma casa vazia
			for i=1,#board.matrix do
				for j=1,#board.matrix[i] do
					if board.matrix[i][j].x <= x and x <= board.matrix[i][j].x + board.matrix[i][j].w and
						board.matrix[i][j].y <= y and y <= board.matrix[i][j].y + board.matrix[i][j].h then
						if board.matrix[i][j].hasPiece == false then --se n tiver peça e existir uma pessa selecionada, transporte ela pra a casa clicada
							pieceIndex,p = Piece.getSelectedPiece()
							if p then
								p:moveToPosition(pieceIndex,board.matrix[i][j])
								sendGameMessage('move ' .. pieceIndex .. ' ' .. board.matrix[i][j].x .. ' ' .. board.matrix[i][j].y) --notificando o oponente do movimento
							end
							addToLog('clicou em uma casa vazia' .. board.matrix[i][j].x .. ' ' .. board.matrix[i][j].y)
						end
					end
				end
			end
		end
	elseif btn == 'm' then
		for k,v in ipairs(pieceArray) do
			if v.x - v.radius <= x and x <= v.x + v.radius and
			 v.y - v.radius <= y and y <= v.y + v.radius then
				if Piece.getSelectedPiece() == nil and v.team == myTeam and v.visible then --se não tiver clicado em nenhuma peça logo antes
					v:kill(k)
					sendGameMessage('kill ' .. k) --notificando o oponente do movimento
				end
			end
		end
	elseif btn == 'r' then
		for k,v in ipairs(pieceArray) do
			if v.x - v.radius <= x and x <= v.x + v.radius and
			 v.y - v.radius <= y and y <= v.y + v.radius then
				if Piece.getSelectedPiece() == nil and v.team == myTeam and v.visible then --se não tiver clicado em nenhuma peça logo antes
					v:toggleKingship(k)
					sendGameMessage('king ' .. k) --notificando o oponente do movimento
				end
			end
		end
	end
end

function Piece:getPosition()
	for i=1,#board.matrix do
		for j=1,#board.matrix[i] do
			if self.x == board.matrix[i][j].x + board.w/16 and
				self.y == board.matrix[i][j].y + board.h/16 then
				return board.matrix[i][j]
			end
		end
	end
	return nil
end

function Piece:moveToPosition(index,newPosition)
	lastPosition = self:getPosition()
	if lastPosition then --a peça estava viva
		self:move(newPosition)
		newPosition.hasPiece = true
		lastPosition.hasPiece = false
		Piece.desselectAll() --desselecionando todas as peças
	else --a peça estava morta
		self:respawn(index,newPosition)
	end
end

function Piece:move(newPosition) --encapsulando o metodo de deslocamento pra evitar muita replicação
	teleport.originX = self.x
	teleport.originY = self.y
	teleport.animate()
	self.x = newPosition.x + board.w/16
	self.y = newPosition.y + board.h/16
end

function Piece:respawn(index,newPosition)
	self:move(newPosition)
	newPosition.hasPiece = true
	deadzone[index].occupied = false
	Piece.desselectAll() --desselecionando todas as peças
end

function Piece:kill(index)
	position = self:getPosition()
	if position then
		position.hasPiece = false
		self:move(deadzone[index])
		deadzone[index].occupied = true
		addToLog('mandou para o morto')
	end
end

function Piece:toggleKingship(index) --criando a dama
	if pieceArray[index].kingship == false then
		pieceArray[index].kingship = true
		pieceArray[index].lineColor = kingshipLineColor
	else
		pieceArray[index].kingship = false
		if pieceArray[index].team == 1 then
			pieceArray[index].lineColor = defaultTeam1LineColor
		else
			pieceArray[index].lineColor = defaultTeam2LineColor
		end
	end
end

function Piece.getSelectedPiece()
	for k,v in ipairs(pieceArray) do
		if v.selected then
			return k,v
		end
	end
	return nil
end

function Piece.desselectAll()
	for k,v in ipairs(pieceArray) do
		if v.selected then
			v.selected = false
		end
	end
end

function mousereleased()

end

-- Scene Drawing
function Piece.draw()
	
	for i=1,#pieceArray do
--		love.graphics.print(#pieceArray .. ' ' .. i .. ' ' .. pieceArray[i].team, 10, 10*i)
		if pieceArray[i].visible then
			love.graphics.setColor(pieceArray[i].fillColor)
			love.graphics.circle( 'fill', pieceArray[i].x, pieceArray[i].y, pieceArray[i].radius, 25 )
			love.graphics.setColor(pieceArray[i].lineColor)
			love.graphics.circle( 'line', pieceArray[i].x, pieceArray[i].y, pieceArray[i].radius, 25 )
			love.graphics.setColor(eGui.themeColor)
		end
	end
	
--	for i=13,32 do
--		love.graphics.circle( 'line', pieceArray[i].x, pieceArray[i].y, pieceArray[i].radius, 25 )
--	end
	
end

function Piece.quit()
	for k,v in ipairs(pieceArray) do
		v.visible = false
	end
	pieceArray = {}
end