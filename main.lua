
require 'eGui'
require 'TSerial'
require 'socketUnderlay'
require 'board'
require 'piece'
require 'teleport'
require 'deadzone'
clientlist = {}
config = {}
config.name = 'anonimo'
config.ip = 'ririari.hopto.org'
config.port = 8080
nodeMode = nil
inGame = false
myTeam = 0 --0: desconectado; 1:cliente; 2:servidor;

function love.load()
	txtlog = {}
	love.keyboard.setKeyRepeat(0.5, 0.02)
	
	eGui.button.create('connectButton', 'Conectar', 0, 0, 100, 25, true, function() tryToConnect('client') end)
	eGui.button.create('hostButton', 'Hospedar', 0, 0, 100, 25, true, function() tryToConnect('server')end)
	eGui.button.create('newGameButton', 'Novo Jogo', 0, love.graphics.getHeight() - 30, 100, 25, true, function() createGame() end)
	eGui.button.create('disconnectButton', 'Desconectar',love.graphics.getWidth() - 105, love.graphics.getHeight() - 30, 100, 25, true, function() disconnect() end)
	
	eGui.label.create('clientListLabel', 'Sala:', 0, 0,true)
	eGui.label.create('nameLabel', 'Nome:', 0, 0,true)
	eGui.label.create('hostAddrLabel', 'Servidor:', 0, 120,true)
	eGui.label.create('portLabel', 'Porta:', 0, 0,true)
	eGui.label.create('deadzoneLabel', 'Morto:', 0, 0,true)
	
	eGui.textbox.create('nameTextBox', config.name, love.graphics.getWidth() - 160, 50, 150, 25, false, true, 16,function() changeName() end)
	eGui.textbox.create('hostAddrTextBox', config.ip, love.graphics.getWidth() - 160, 135, 150, 25, false, true, 20)
	eGui.textbox.create('portTextBox', config.port, love.graphics.getWidth() - 160, 190, 150, 25, false, true, 5)
	eGui.textbox.create('chatTextBox', '', 10, 445, 570, 25, true, true, 64, function() sendTextMessage(eGui.getItemByID('chatTextBox')) end)
	
	eGui.textarea.create('logTextArea', {}, 0, 0,570,150,true)
	eGui.textarea.create('clientListTextArea', {}, 0, 0,150,360,true)
	
	--arrumando todo o layout relativamente a partir do botão de desconectar e de novo jogo
	eGui.placeOnLeft(eGui.getItemByID('newGameButton'),eGui.getItemByID('disconnectButton'))
	
	eGui.placeAbove(eGui.getItemByID('hostButton'),eGui.getItemByID('disconnectButton'))
	eGui.placeOnRight(eGui.getItemByID('hostButton'),eGui.getItemByID('newGameButton'))
	
	eGui.placeAbove(eGui.getItemByID('connectButton'),eGui.getItemByID('newGameButton'))
	eGui.placeOnLeft(eGui.getItemByID('connectButton'),eGui.getItemByID('hostButton'))
	
	eGui.placeOnLeft(eGui.getItemByID('chatTextBox'),eGui.getItemByID('connectButton'))
	eGui.placeBelow(eGui.getItemByID('chatTextBox'),eGui.getItemByID('connectButton'))
	
	eGui.placeOnLeft(eGui.getItemByID('logTextArea'),eGui.getItemByID('connectButton'))
	eGui.placeAbove(eGui.getItemByID('logTextArea'),eGui.getItemByID('chatTextBox'))
	
	eGui.placeOnRight(eGui.getItemByID('portTextBox'),eGui.getItemByID('logTextArea'))
	eGui.placeAbove(eGui.getItemByID('portTextBox'),eGui.getItemByID('hostButton'))
	
	eGui.placeOnRight(eGui.getItemByID('portLabel'),eGui.getItemByID('logTextArea'))
	eGui.placeAbove(eGui.getItemByID('portLabel'),eGui.getItemByID('portTextBox'))
	
	eGui.placeOnRight(eGui.getItemByID('hostAddrTextBox'),eGui.getItemByID('logTextArea'))
	eGui.placeAbove(eGui.getItemByID('hostAddrTextBox'),eGui.getItemByID('portLabel'))
	
	eGui.placeOnRight(eGui.getItemByID('hostAddrLabel'),eGui.getItemByID('logTextArea'))
	eGui.placeAbove(eGui.getItemByID('hostAddrLabel'),eGui.getItemByID('hostAddrTextBox'))
	
	eGui.placeOnRight(eGui.getItemByID('nameTextBox'),eGui.getItemByID('logTextArea'))
	eGui.placeAbove(eGui.getItemByID('nameTextBox'),eGui.getItemByID('hostAddrLabel'))
	
	eGui.placeOnRight(eGui.getItemByID('nameLabel'),eGui.getItemByID('logTextArea'))
	eGui.placeAbove(eGui.getItemByID('nameLabel'),eGui.getItemByID('nameTextBox'))
	
	eGui.placeOnRight(eGui.getItemByID('clientListTextArea'),eGui.getItemByID('logTextArea'))
	eGui.placeAbove(eGui.getItemByID('clientListTextArea'),eGui.getItemByID('nameLabel'))
	
	eGui.placeOnRight(eGui.getItemByID('clientListLabel'),eGui.getItemByID('logTextArea'))
	eGui.placeAbove(eGui.getItemByID('clientListLabel'),eGui.getItemByID('clientListTextArea'))
	
	eGui.placeOnLeft(board,eGui.getItemByID('clientListTextArea'))
	eGui.placeAbove(board,eGui.getItemByID('logTextArea'))
	
	eGui.placeOnLeft(deadzone,board)
	eGui.placeAbove(deadzone,eGui.getItemByID('logTextArea'))
	
	eGui.placeAbove(eGui.getItemByID('deadzoneLabel'),deadzone)
	eGui.getItemByID('deadzoneLabel').x = deadzone.x
	
	board.load()
	deadzone.load()
	
end

function tryToConnect(mode) --função a ser chamada pelos botões de conexão ou hospedagem
	if nodeMode then
		addToLog('Você ja está conectado')
	else
		if mode == 'client' then
			addToLog('tentando conectar ao servidor')
			socketUnderlay.client = socketUnderlay.connect(config.ip,config.port)
			if socketUnderlay.client then
				nodeMode = mode
				myTeam = 1
				eGui.themeColor = {0,255,0,255}
				board.themeColor = {0,255,0,125}
			end
		elseif mode == 'server' then
			addToLog('hospedando conexao')
			local clist = packSocketList()
			clientlist = TSerial.unpack(clist)
--			if not socketUnderlay.server then --se n tiver amarrado o tcp object na porta ainda, crie o servidor
				socketUnderlay.server = socketUnderlay.host(config.port)
--			end
			if socketUnderlay.server then
				nodeMode = mode
				myTeam = 2
				eGui.themeColor = {255,100,0,255}
				board.themeColor = {255,100,0,125}
			end
		end
	end
end

function createGame()
	if nodeMode == nil or #clientlist < 2 then
		addToLog('voce precisa estar conectado a alguem para jogar')
	else
		loadGame()
		sendGameMessage('start')
	end
end

function loadGame()
	if inGame then
		addToLog('voce ja esta jogando')
	else--se tiver conectado, instancia as peças, o sistema de particulas e avisa pros clientes conectados que o jogo vai começar
		addToLog('criando jogo')
		Piece.load()
		inGame = true
		teleport.load()
	end
end

function disconnect()
	addToLog('Desconectando')
	love.quit()
	nodeMode = nil
	inGame = false
	myTeam = 0
	clientlist = {}
	eGui.themeColor = {0,255,255,255}
	board.themeColor = {0,255,255,125}
end

function sendTextMessage(eGuiItem)

	if nodeMode == 'client' then
		socketUnderlay.sendToServer('%S01' .. eGuiItem.text .. '\n')
	elseif nodeMode == 'server' then
		addToLog(config.name..': '..eGuiItem.text..'\n') --dando print no proprio log
		socketUnderlay.broadcastMessage('%C01'..config.name..': '..eGuiItem.text..'\n')
	end

	eGuiItem.text = ''
end

function sendGameMessage(message)
	if nodeMode == 'client' then
		socketUnderlay.sendToServer('%S03' .. message .. '\n')
	elseif nodeMode == 'server' then
		socketUnderlay.broadcastMessage('%C03' .. message .. '\n')
	end
end

function changeName()
	--fazer função de mudar o nome aqui
end

function addToLog(msg)
	table.insert(txtlog, msg)
	if #txtlog > eGui.getItemByID('logTextArea').h/15 then
		repeat table.remove(txtlog, 1) until #txtlog <= eGui.getItemByID('logTextArea').h/15
	end
end

function love.update(dt)
	eGui.update(dt)
	teleport.update(dt)
	if nodeMode == 'server' then
		socketUnderlay.updateServer()
	elseif	nodeMode == 'client' then
		socketUnderlay.updateClient()
	else
		config.name = eGui.getItemByID('nameTextBox').text
		config.ip = eGui.getItemByID('hostAddrTextBox').text
		config.port = eGui.getItemByID('portTextBox').text
	end
	
	eGui.getItemByID('logTextArea').text = txtlog
	
end

function love.draw()
	eGui.draw()
	board.draw()
	deadzone.draw()
	Piece.draw()
	teleport.draw()
	for k, v in ipairs(clientlist) do
		love.graphics.print(v, eGui.getItemByID('clientListTextArea').x+.5, eGui.getItemByID('clientListTextArea').y+.5 + (k-1)*15)
	end
end

function love.keypressed(key, unicode)
	eGui.keyboard(key, unicode)
end

function love.quit()
	if client then
		client:send('%S04\n')
	elseif server then
		socketUnderlay.quit()
	end
	Piece.quit()
end

function love.mousepressed(x, y, btn)
	eGui.mouse(x, y, btn)
	Piece.mousepressed(x,y,btn)
end

-- Command Prefixes
-- %C01 chat message
-- %C02 client list