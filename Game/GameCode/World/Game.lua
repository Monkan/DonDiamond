local FileIO 			= require("World/FileIO")
local Room 				= require("World/Room")
local TexturePacker 	= require("Util/TexturePacker")
local Player			= require("World/Player")
local Enemy				= require("World/Enemy")
local CollisionFilters 	= require("World/CollisionFilters")
local World				= require("World/World")

local Game = Class()

local RoomDimensionsWorld = { 1280, 720 }
local TileDimensions = { 40, 40 }

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------
function Game:Constructor(mainLayer, physicsWorld)
	
	--MOAIGfxDevice.getFrameBuffer():setClearColor(1.0, 1.0, 1.0, 1.0)

	self.layer = mainLayer
	self.physicsWorld = physicsWorld
	
	self.enemies = {}
	self.projectiles = {}
	self.rooms = {}

--[[
	-- dtreadgold: Set up camera
	self.camera = MOAICamera.new()
	layer:setCamera( self.camera )

	local cameraFitter = MOAICameraFitter2D.new()	
	cameraFitter:setViewport( layer.viewport )
	cameraFitter:setCamera( self.camera )
	cameraFitter:setBounds( -1000, -1000, 1000, 1000 )
	cameraFitter:setMin( 512 )
	cameraFitter:start()

--]]
	
	self.world = World(mainLayer, physicsWorld)

	self.world.enemies = self.enemies
	self.world.projectiles = self.projectiles
	self.world.rooms = self.rooms
	
	self:CreateBackground()
	self:CreateRoomGrid()
	
	self.player = Player(self.world)
	self.world.player = self.player
	
	-- dtreadgold: Set up the first room
	self:MoveToRoom()

end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Game:SaveWorld()
	--FileIO.Save("test.json")
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Game:LoadWorld()
	--FileIO.Load("test.json")
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Game:Update()
	self.player:Update()
	if self.player.dead then
		self:Restart()
	end
	
	-- dtreadgold: Update all enemies
	for enemyIndex, enemy in ipairs(self.enemies) do
		enemy:Update()
		
		if enemy.dead then
			enemy.body:destroy()
			self.layer:removeProp(enemy.prop)
			table.remove(self.enemies, enemyIndex)
		end
	end
	
	-- dtreadgold: Remove any dead projectiles
	for projectileIndex, projectile in ipairs(self.projectiles) do
		if projectile.dead then
			projectile.body:destroy()
			self.layer:removeProp(projectile.prop)
			table.remove(self.projectiles, projectileIndex)
		end
	end
	
	-- dtreadgold: Check if the room has been cleared of enemies
	if #self.enemies == 0 then
		self:RoomFinished()
	end
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Game:RoomFinished()
	-- dtreadgold: Create a key pickup to open a door
	for doorIndex, door in ipairs(self.doors) do
		door:setActive(false)
	end
	
	self:MoveToRoom()
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Game:MoveToRoom()
	self.currentRoom = Room()
	table.insert(self.rooms, self.currentRoom)

	self:PopulateRoom()
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Game:PopulateRoom()
	local numEnemies = #self.rooms
	for enemyCount = 1, numEnemies do
		self:CreateEnemy()
	end
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Game:Restart()
	self.player.dead = false
	self.player.health = self.player.initialHealth
	self.player.body:setTransform(0, 0, 0)
	
	self.currentRoom = nil
	self.rooms = {}
	
	for enemyIndex, enemy in ipairs(self.enemies) do
		enemy.body:destroy()
		self.layer:removeProp(enemy.prop)
	end
	self.enemies = {}
	
	for projectileIndex, projectile in ipairs(self.projectiles) do
		projectile.body:destroy()
		self.layer:removeProp(projectile.prop)
	end
	self.projectiles = {}
	
	self.world.enemies = self.enemies
	self.world.projectiles = self.projectiles
	self.world.rooms = self.rooms
	
	-- dtreadgold: Start on the 1st room again
	self:MoveToRoom()
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Game:CreateEnemy()
	local layer = self.layer

	local enemy = Enemy(self.world)
	table.insert(self.enemies, enemy)
	
	local position =
	{
		math.random( (-RoomDimensionsWorld[1] / 2) + TileDimensions[1], (RoomDimensionsWorld[1] / 2) - TileDimensions[1] ),
		math.random( (-RoomDimensionsWorld[2] / 2) + TileDimensions[2], (RoomDimensionsWorld[2] / 2) - TileDimensions[2] ),
	}
	enemy.body:setTransform(position[1], position[2], 0)
end


--------------------------------------------------------------------------------
-- dtreadgold: Set up background image
--------------------------------------------------------------------------------
function Game:CreateBackground()
	local layer = self.layer

	local backgroundQuad = MOAIGfxQuad2D.new ()
	backgroundQuad:setTexture ( GRAPHICS_DIR .. "background.png" )
	backgroundQuad:setRect ( -RoomDimensionsWorld[1] / 2, -RoomDimensionsWorld[2] / 2, RoomDimensionsWorld[1] / 2, RoomDimensionsWorld[2] / 2 )

	local backgroundProp = MOAIProp2D.new()
	backgroundProp:setDeck ( backgroundQuad )
	--layer:insertProp ( backgroundProp )
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Game:CreateRoomGrid()
	local layer = self.layer

	local roomDimensionsTiles = { 32, 18 } --{ math.ceil(RoomDimensionsWorld[1] / TileDimensions[1]), math.ceil(RoomDimensionsWorld[2] / TileDimensions[2]) }

	-- dtreadgold: Setup the room grid
	local grid = MOAIGrid.new ()
	grid:initRectGrid( roomDimensionsTiles[1], roomDimensionsTiles[2], TileDimensions[1], TileDimensions[2], 0, 0, 1, 1 )

	local tileDeck = TexturePacker:Load(GRAPHICS_DIR .. "roomTiles.lua", GRAPHICS_DIR .. "roomTiles.png", { x0 = 0, y0 = 0, x1 = 1, y1 = 1 })
	local roomGridProp = MOAIProp2D.new()
	roomGridProp:setDeck( tileDeck )
	roomGridProp:setGrid( grid )
	
	for tileX = 1, roomDimensionsTiles[1] do
		for tileY = 1, roomDimensionsTiles[2] do
			if (tileX == 1 or tileX == roomDimensionsTiles[1]) or (tileY == 1 or tileY == roomDimensionsTiles[2]) then
				grid:setTile( tileX, tileY,	1 )
			else
				grid:setTile( tileX, tileY,	3 )
			end
		end
	end
	
	local gridOffset = {}
	gridOffset[1] = -(RoomDimensionsWorld[1] / 2) - (TileDimensions[1] / 2)
	gridOffset[2] = -(RoomDimensionsWorld[2] / 2) - (TileDimensions[2] / 2)
	roomGridProp:setLoc( gridOffset[1], gridOffset[2] )
	
	roomGridProp:forceUpdate ()
	layer:insertProp ( roomGridProp )
	
	self.roomGrid = roomGridProp
	
	-- dtreadgold: Create wall physics
	local wallPositions =
	{
		{ -(RoomDimensionsWorld[1] /2) + (TileDimensions[1] / 2), 0 },
		{ 0, (RoomDimensionsWorld[2] / 2) - (TileDimensions[2] / 2) },
		{ (RoomDimensionsWorld[1] / 2) - (TileDimensions[1] / 2), 0 },
		{ 0, -(RoomDimensionsWorld[2] / 2) + (TileDimensions[2] / 2) },
	}

	for wallIndex, wallPosition in ipairs(wallPositions) do
		local wallBody = self.physicsWorld:addBody( MOAIBox2DBody.STATIC )
		local wallDimensions = {}
		if wallIndex % 2 == 1 then
			wallDimensions = { TileDimensions[1], RoomDimensionsWorld[2] }
		else
			wallDimensions = { RoomDimensionsWorld[1], TileDimensions[2] }
		end

		local fixture = wallBody:addRect( -wallDimensions[1] / 2, -wallDimensions[2] / 2, wallDimensions[1] / 2, wallDimensions[2] / 2 )
		fixture:setFilter( CollisionFilters.Category.Environment, CollisionFilters.Mask.Environment )
		wallBody:setTransform(wallPosition[1], wallPosition[2], 0)
	end
	
	-- dtreadgold: Create door tiles
	local doorSize = 4
	
	-- dtreadgold: Top door
	for doorOffsetIndex = 1, doorSize do
		local tileXPos = (roomDimensionsTiles[1] / 2) - (doorSize / 2) + doorOffsetIndex
		grid:setTile( tileXPos, roomDimensionsTiles[2], 2 )
	end
	
	-- dtreadgold: Right door
	for doorOffsetIndex = 1, doorSize do
		local tileYPos = (roomDimensionsTiles[2] / 2) - (doorSize / 2) + doorOffsetIndex
		grid:setTile( roomDimensionsTiles[1], tileYPos, 2 )
	end
	
	-- dtreadgold: Bottom door
	for doorOffsetIndex = 1, doorSize do
		local tileXPos = (roomDimensionsTiles[1] / 2) - (doorSize / 2) + doorOffsetIndex
		grid:setTile( tileXPos, 1, 2 )
	end
	
	-- dtreadgold: Left door
	for doorOffsetIndex = 1, doorSize do
		local tileYPos = (roomDimensionsTiles[2] / 2) - (doorSize / 2) + doorOffsetIndex
		grid:setTile( 1, tileYPos, 2 )
	end


	-- dtreadgold: Create door physics
	self.doors = {}
	for wallIndex, wallPosition in ipairs(wallPositions) do
		local doorBody = self.physicsWorld:addBody( MOAIBox2DBody.STATIC )
		local doorDimensions = {}
		if wallIndex % 2 == 1 then
			doorDimensions = { TileDimensions[1], TileDimensions[2] * doorSize }
		else
			doorDimensions = { TileDimensions[1] * doorSize, TileDimensions[2] }
		end

		local fixture = doorBody:addRect( -doorDimensions[1] / 2, -doorDimensions[2] / 2, doorDimensions[1] / 2, doorDimensions[2] / 2 )
		fixture:setFilter( CollisionFilters.Category.Environment, CollisionFilters.Mask.Environment )
		doorBody:setTransform(wallPosition[1], wallPosition[2], 0)
		
		table.insert(self.doors, doorBody)
	end
end


return Game