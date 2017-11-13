-- Filename: teleport.lua
-- Author: Francisco Ari Josino Junior
-- Date: 2012-06-10

require 'eGui'

teleport = {}
teleport.originX = 0
teleport.originY = 0

function teleport.load()
	--1a. create a blank 4px*4px image data
	tpSquare = love.image.newImageData(4, 4)
	--1b. fill that blank image data
	for x = 0, 3 do
		for y = 0, 3 do
			tpSquare:setPixel(x, y, eGui.themeColor[1],eGui.themeColor[2],eGui.themeColor[3],eGui.themeColor[4])
		end
	end
  
  --2. create an image from that image data
	image = love.graphics.newImage(tpSquare)
  
	--3a. create a new particle system which uses that image, set the maximum amount of particles (images) that could exist at the same time to 256
	originParticle = love.graphics.newParticleSystem(image, 256)
	--3b. set various elements of that particle system, please refer the wiki for complete listing
	originParticle:setEmissionRate          (100)
	originParticle:setEmitterLifetime       (0.1)
	originParticle:setParticleLifetime      (0.2)
	originParticle:setPosition              (0, 0)
	originParticle:setDirection             (0)
	originParticle:setSpread                (10)
	originParticle:setSpeed                 (100, 100)
	originParticle:setLinearAcceleration    (0,-50,0,-50)
	originParticle:setRadialAcceleration    (100)
	originParticle:setTangentialAcceleration(0)
	originParticle:setSizes                 (1)
	originParticle:setSizeVariation         (0.5)
	originParticle:setRotation              (0)
	originParticle:setSpin                  (0)
	originParticle:setSpinVariation         (0)
	originParticle:setColors                (255, 255, 255, 255, 255, 255, 255, 255)
	originParticle:stop() --this stop is to prevent any glitch that could happen after the particle system is created

end

function teleport.update(dt)
	if inGame then
		originParticle:update(dt)
	end

end

function teleport.draw()
	if inGame then
		--5. draw the particle system, with its origin (0, 0) located at love's 20, 20. Compare this origin position with the particle system's emitter position being set by "p:setPosition(50, 50)" in love.load
		love.graphics.draw(originParticle, teleport.originX, teleport.originY)
	end
end


function teleport.animate()
	--4a. on each frame, the particle system should be started/burst. try to move this line to love.load instead and see what happens
	originParticle:start()
end

function teleport.paintImage()
	for x = 0, 3 do
		for y = 0, 3 do
			tpSquare:setPixel(x, y, 0, 255, 0, 255)
		end
	end
end