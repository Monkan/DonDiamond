Class = require "Util/Class"
require "Util/Table"
require "Util/Math"

local Game = require "World/Game"


CONTENT_DIR = "../Content/"
GRAPHICS_DIR = CONTENT_DIR .. "Graphics/"

local game = Game()

-- Run the game
function main ()
	while true do
		game:Update()
		
		coroutine.yield ()
	end
end

local thread = MOAIThread.new ()
thread:run ( main )
