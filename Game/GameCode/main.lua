Class = require "Util/Class"
require "Util/Table"
require "Util/Math"

local Game = require "World/Game"


CONTENT_DIR = "../Content/"
GRAPHICS_DIR = CONTENT_DIR .. "Graphics/"

local resolution = { 1280, 720 }

local viewport = MOAIViewport.new()
viewport:setSize( unpack(resolution) )
viewport:setScale( unpack(resolution) )

local mainLayer = MOAILayer2D.new()
mainLayer:setViewport( viewport )
mainLayer.viewport = viewport
MOAISim.pushRenderPass( mainLayer )

-- dtreadgold: Set up box2d world
local physicsWorld = MOAIBox2DWorld.new()
--physicsWorld:setDebugDrawEnabled(true)
physicsWorld:setDebugDrawEnabled(false)
physicsWorld:setGravity( 0, 0 )
physicsWorld:setUnitsToMeters( .05 )
physicsWorld:start()

local physicsLayer = MOAILayer2D.new()
physicsLayer:setViewport( viewport )
physicsLayer.viewport = viewport
MOAISim.pushRenderPass( physicsLayer )

--mainLayer:setBox2DWorld( physicsWorld )
physicsLayer:setBox2DWorld( physicsWorld )

MOAISim.openWindow( "test", unpack(resolution) )

local game = Game(mainLayer, physicsWorld)

-- dtreadgold: Run the game
function main ()
	while true do
		game:Update()
		
		coroutine.yield ()
	end
end

local thread = MOAIThread.new ()
thread:run ( main )
