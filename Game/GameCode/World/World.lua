local FileIO 			= require("World/FileIO")
local Room 				= require("World/Room")
local TexturePacker 	= require("Util/TexturePacker")
local Player			= require("World/Player")
local Enemy				= require("World/Enemy")
local CollisionFilters 	= require("World/CollisionFilters")

local World = Class()

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------
function World:Constructor(mainLayer, physicsWorld)
	self.layer = mainLayer
	self.physicsWorld = physicsWorld
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function World:SaveWorld()
	--FileIO.Save("test.json")
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function World:LoadWorld()
	--FileIO.Load("test.json")
end

return World