require 'secs'

eGui = {}
eGui.items = {}
eGui.themeColor = {0,255,255,255}

eGui.textbox = class:new()
eGui.textbox.type = 'textbox'
eGui.textbox.name = 'default'
eGui.textbox.text = 'default'
eGui.textbox.x = 0
eGui.textbox.y = 0
eGui.textbox.w = 100
eGui.textbox.h = 25
eGui.textbox.focus = false
eGui.textbox.visible = true
eGui.textbox.exec = function() end

eGui.button = class:new()
eGui.button.type = 'button'
eGui.button.name = 'default'
eGui.button.text = 'New Button'
eGui.button.x = 0
eGui.button.y = 0
eGui.button.w = 100
eGui.button.h = 25
eGui.button.focus = false
eGui.button.visible = true
eGui.button.onClick = function() end

eGui.label = class:new()
eGui.label.type = 'label'
eGui.label.name = 'default'
eGui.label.text = 'default'
eGui.label.x = 0
eGui.label.y = 0
eGui.label.w = 0
eGui.label.h = 0
eGui.label.visible = true

eGui.textarea = class:new()
eGui.textarea.type = 'textarea'
eGui.textarea.name = 'default'
eGui.textarea.text = 'default'
eGui.textarea.x = 0
eGui.textarea.y = 0
eGui.textarea.w = 0
eGui.textarea.h = 0
eGui.textarea.visible = true

function eGui.placeAbove(arg1,arg2) --coloca o primeiro parametro 5px acima do segundo
	arg1.y = arg2.y - (arg1.h + 5)
end

function eGui.placeBelow(arg1,arg2) --coloca o primeiro parametro 5px abaixo do segundo
	arg1.y = arg2.y + (arg2.h + 5)
end

function eGui.placeOnRight(arg1,arg2) --coloca o primeiro parametro 5px à direita do segundo
	arg1.x = arg2.x + (arg2.w + 5)
end

function eGui.placeOnLeft(arg1,arg2) --coloca o primeiro parametro 5px à esquerda do segundo
	arg1.x = arg2.x - (arg1.w + 5)
end

function eGui.textbox.create(id, text, x, y, w, h, focus, visible, limit, exec)
	name = eGui.textbox:new()
	name.name = id
	name.text = text
	name.x = x
	name.y = y
	name.w = w
	name.h = h
	name.focus = focus
	name.visible = visible
	name.limit = limit
	name.exec = exec
	table.insert(eGui.items, name)
end

function eGui.button.create(id, text, x, y, w, h, visible, func)
	name = eGui.button:new()
	name.name = id
	name.text = text
	name.x = x
	name.y = y
	name.w = w
	name.h = h
	name.visible = visible
	name.onClick = func
	table.insert(eGui.items, name)
end

function eGui.label.create(id, text, x, y, visible)
	name = eGui.label:new()
	name.name = id
	name.text = text
	name.x = x
	name.y = y
	name.w = string.len(text) * 15 --considerando 15 pixels por caractere
	name.h = 15
	name.visible = visible
	table.insert(eGui.items, name)
end

function eGui.textarea.create(id, text, x, y, w, h, visible)
	name = eGui.textarea:new()
	name.name = id
	name.text = text
	name.x = x
	name.y = y
	name.w = w
	name.h = h
	name.visible = visible
	table.insert(eGui.items, name)
end

function eGui.draw()
	for k,v in ipairs(eGui.items) do
		if v.visible == true then
			if v.type == 'textbox' then
				if v.focus == true then
					love.graphics.rectangle('line',v.x+.5, v.y+.5, v.w, v.h)
					love.graphics.print(v.text..'|', v.x + 5, v.y + 6)
				else
					love.graphics.rectangle('line',v.x+.5, v.y+.5, v.w, v.h)
					love.graphics.print(v.text, v.x + 5, v.y + 6)
				end
			elseif v.type == 'button' then
				love.graphics.rectangle('line',v.x+.5, v.y+.5, v.w, v.h)
				love.graphics.rectangle('line',v.x+2.5, v.y+2.5, v.w-4, v.h-4)
				love.graphics.print(v.text, v.x + 5, v.y + 6)
			elseif v.type == 'label' then
				love.graphics.print(v.text, v.x, v.y)
			elseif 	v.type == 'textarea' then
				love.graphics.rectangle('line',v.x+.5, v.y+.5, v.w, v.h)
				for l,w in ipairs(v.text) do
					love.graphics.print(w, v.x+.5, v.y+.5+(l-1)*15)
				end
			end
		end
	end
	love.graphics.setColor(eGui.themeColor)
end

function eGui.update(dt)
	-- Does nothing yet.
end

function eGui.getItemByID(id)
	for k,v in ipairs(eGui.items) do
		if v.name == id then
			return v
		end
	end
end

function eGui.mouse(x, y, btn)
	print("egui mouse "..btn.." "..table.getn(eGui.items)..type(btn))
	for k,v in ipairs(eGui.items) do
		if btn == 1 then
			print("herp")
			if x > v.x and x < v.x + v.w and y > v.y and y < v.y + v.h then
				if v.type == 'textbox' and v.visible == true then
					v.focus = true
				elseif v.type == 'button' and v.visible == true then
					v.onClick()
				end
			else
				if v.type == 'textbox' then v.focus = false end
			end
		end
	end
end

function eGui.keyboard(key, unicode)
	if key == 'backspace' then
		for k,v in ipairs(eGui.items) do
			if v.type == 'textbox' and v.focus == true then
				v.text = string.sub(v.text, 1, -2)
			end
		end
	elseif key == 'return' then
		for k,v in ipairs(eGui.items) do
			if v.type == 'textbox' and v.focus == true and v.exec then v.exec() end
		end
	elseif key == 'kpenter' then
		for k,v in ipairs(eGui.items) do
			if v.type == 'textbox' and v.focus == true and v.exec then v.exec() end
		end
	else
		for k,v in ipairs(eGui.items) do
			if v.type == 'textbox' and v.focus == true then
				if unicode > 31 and unicode < 127 then
					if string.len(v.text) <= v.limit then
						k = string.char(unicode)
						v.text = v.text..k
					end
				end
			end
		end
	end
end