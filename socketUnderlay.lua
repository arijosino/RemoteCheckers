-- Prefixos de troca de mensagens
-- %S01 mensagem de texto enviada pelo cliente
-- %S02 informação de cliente enviada pelo mesmo
-- %S03 informação de jogo vinda do cliente
-- %S04 cliente desconectado

-- %C01 mensagem de texto enviada pelo servidor
-- %C02 informação de servidor enviada pelo mesmo
-- %C03 informação de jogo vinda do servidor

require 'TSerial'
require 'board'
local socket = require 'socket'
socketUnderlay = {client,server}
connections = {}

--se estiver em modo servidor, essa função será chamada
function socketUnderlay.host(port)
	server = socket.tcp() --criando TCP master object
	server:bind('*',port)--amarrando o TCP master object como servidor na porta especificada
	server:settimeout(0) --tirando timeout(depois eu vejo se vale mto a pena botar timeout ou sei la)
	ip, port = server:getsockname() --pegando ip e porta locais
	server:listen() --definindo o TCP master object como servidor
	return server
end

--se estiver em modo cliente, chama essa função
function socketUnderlay.connect(ip,port)
	client = socket.tcp()
	client:settimeout(10)
	local success = client:connect(ip, port)
	if not success then 
		addToLog('Não foi possivel conectar ao servidor, por favor cheque o endereço do mesmo.')
		return nil
	else
		client:settimeout(0)
		client:send('%S02'..config.name..'\n')
		return client	
	end
end

--callBack de servidor
function socketUnderlay.updateServer()
	local clientConnection = socketUnderlay.server:accept() --retorna um objeto cliente caso algum cliente tenha se conectado e não tiver nenhum cliente ja conectado
	
	if clientConnection then --se alguem tiver se conectado…
		clientConnection:settimeout(0)
		table.insert(connections, clientConnection) --adicionando o cliente na lista de clientes
		clientConnection:send('%C01'..'Conectado a ' .. ip .. ":" .. config.port ..'\n') -- enviando mensagem de handshake para o cliente
	end
	
	for k,v in ipairs(connections) do --para cada elemento na lista de conexões
		local msg = v:receive('*l') --lendo a proxima linha enviada por um cliente ao servidor
		if msg then --se a linha é não nula…
			--separando o msg em prefixo e conteudo
			local code = string.sub(msg, 1, 4)
			local messageContent = string.sub (msg, 5)
			
			if code == '%S01' then --se o prefixo for %S01, eh msg de chat quando este node eh um servidor
				
				addToLog(connections[v]..': '..messageContent..'\n') --dando print no proprio log
				socketUnderlay.broadcastMessage('%C01'..connections[v]..': '..messageContent..'\n') -- repassando a mensagem para todos os clientes conecatos a este node
				
			elseif code == '%S02' then --se o prefixo for %S02
				if connections[v] then --se o cliente ja existia, eh pq mudou de nome
					local old = connections[v]
					connections[v] = messageContent
					addToLog(old..' mudou de nome e agora se chama '..connections[v]..'\n')
					socketUnderlay.broadcastMessage('%C01'..old..' mudou de nome e agora se chama '..connections[v]..'\n') --atualizando o nome do usuario
				else --se n, eh pq entrou na sala agora
					connections[v] = messageContent
					addToLog(messageContent..' entrou na sala.\n')
					socketUnderlay.broadcastMessage('%C01'..messageContent..' entrou na sala.\n')
					--depois de tudo, atualiza a lista de usuarios conectados
					local clist = packSocketList()
					clientlist = TSerial.unpack(clist)
					socketUnderlay.broadcastMessage('%C02'..clist..'\n')
				end
				
			elseif code == '%S03'then
				if(messageContent == 'start')then
					loadGame()
				elseif(string.sub(messageContent,1,4) == 'move')then -- se for codigo de movimento de peças...
					socketUnderlay.movePiece(messageContent)
				elseif(string.sub(messageContent,1,4) == 'kill')then -- se for codigo de matar peça...
					parameters = string.sub(messageContent,4)
					pieceIndex = string.match(parameters, '[%d]+') --pegando o primeiro parametro
					pieceArray[tonumber(pieceIndex)]:kill(tonumber(pieceIndex))
				elseif(string.sub(messageContent,1,4) == 'king')then -- se for codigo de matar peça...
					parameters = string.sub(messageContent,4)
					pieceIndex = string.match(parameters, '[%d]+') --pegando o primeiro parametro
					pieceArray[tonumber(pieceIndex)]:toggleKingship(tonumber(pieceIndex))
				end
			elseif code == '%S04' then --alguem saiu da sala
				addToLog(connections[v]..' saiu da sala.\n')
				for l, w in ipairs(connections) do
					w:send('%C01'..connections[v]..' saiu da sala.\n')
				end
				table.remove(connections, k)
				v:close()
				local clist = packSocketList()
				clientlist = TSerial.unpack(clist)
				socketUnderlay.broadcastMessage('%C02'..clist..'\n')
			end
		end
	end
end

function socketUnderlay.updateClient()
	local msg = socketUnderlay.client:receive()
	if msg then
		local code = string.sub(msg, 1, 4)
		local messageContent = string.sub (msg, 5)
		if code == '%C01' then
			addToLog(messageContent)
		elseif code == '%C02' then
			clientlist = TSerial.unpack(messageContent)
		elseif code == '%C03' then
			if(messageContent == 'start')then
				loadGame()
			elseif(string.sub(messageContent,1,4) == 'move') then
				socketUnderlay.movePiece(messageContent)
			elseif(string.sub(messageContent,1,4) == 'kill')then -- se for codigo de matar peça...
				parameters = string.sub(messageContent,4)
				pieceIndex = string.match(parameters, '[%d]+') --pegando o primeiro parametro
				pieceArray[tonumber(pieceIndex)]:kill(tonumber(pieceIndex))
			elseif(string.sub(messageContent,1,4) == 'king')then -- se for codigo de matar peça...
				parameters = string.sub(messageContent,4)
				pieceIndex = string.match(parameters, '[%d]+') --pegando o primeiro parametro
				pieceArray[tonumber(pieceIndex)]:toggleKingship(tonumber(pieceIndex))
			end
		end
	end
end

function socketUnderlay.quit()
	for k,v in ipairs(connections) do
		v:send('%C01SERVER CLOSED'..'\n')
		for k,v in ipairs(connections) do
			v:close()
		end
	end
	server:close()
	connections = {}
end

function packSocketList() --serializa e empacota a lista de conexões
	local t = {}
	table.insert(t,config.name) --inserindo o proprio nome na lista
	for k, v in ipairs(connections) do
		table.insert(t, connections[v])
	end
	local clist = TSerial.pack(t)
	return clist
end
function socketUnderlay.broadcastMessage(message)
	for k, v in ipairs(connections) do
		v:send(message)
	end
end

function socketUnderlay.sendToServer(message)
	if client then
		client:send(message)
	else
		addToLog('Voce nao esta conectado')
	end
end

function socketUnderlay.movePiece(messageContent)
	parameters = string.sub(messageContent,4)
	pieceIndex = string.match(parameters, '[%d]+') --pegando o primeiro parametro
	parameters = string.sub(parameters,string.find(parameters,pieceIndex) + #pieceIndex) --comendo a string de parametros
	
	destinationX = string.match(parameters, '[%d]+') --pegando o segundo parametro
	parameters = string.sub(parameters,string.find(parameters,destinationX) + #destinationX) --comendo a string de parametros
	
	destinationY = string.match(parameters, '[%d]+') --pegando o terceiro parametro
	
	addToLog('movendo ' .. pieceIndex .. ' ' .. destinationX .. ' ' .. destinationY)
	position = board.getPositionByCoordinates(tonumber(destinationX),tonumber(destinationY))
	if position then
		pieceArray[tonumber(pieceIndex)]:moveToPosition(tonumber(pieceIndex),position)
	end
end
