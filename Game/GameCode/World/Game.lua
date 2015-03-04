local FileIO 			= require("World/FileIO")
local Room 				= require("World/Room")
local TexturePacker 	= require("Util/TexturePacker")
local Player			= require("World/Player")
local Enemy				= require("World/Enemy")
local CollisionFilters 	= require("World/CollisionFilters")
local World				= require("World/World")
local SpawnList			= require("World/SpawnList")

local Game = Class()

local RoomDimensionsWorld = { 720, 1280 }
local TileDimensions = { 40, 40 }
local RoomDimensionsTiles = { math.ceil(RoomDimensionsWorld[1] / TileDimensions[1]), math.ceil(RoomDimensionsWorld[2] / TileDimensions[2]) }

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------
function Game:Constructor()

--[[
	MOAISim.setHistogramEnabled(true)
	MOAISim.setLeakTrackingEnabled(true)
--]]

	math.randomseed(MOAISim.getDeviceTime())

	local screenWidth = MOAIEnvironment.horizontalResolution or 360
	local screenHeight = MOAIEnvironment.verticalResolution or 640

	MOAISim.openWindow( "DonDiamond", screenWidth, screenHeight )

	local viewport = MOAIViewport.new()
	viewport:setSize( screenWidth, screenHeight )
	viewport:setScale( screenWidth, screenHeight )

	local mainLayer = MOAILayer2D.new()
	mainLayer:setViewport( viewport )
	mainLayer.viewport = viewport
	MOAISim.pushRenderPass( mainLayer )

	-- Set up box2d world
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

	self.layer = mainLayer
	self.physicsWorld = physicsWorld
	
	self:CreateBackground()
	self:CreateRoomGrid()
	
	self.world = World(mainLayer, physicsWorld)
	self.rooms = self.world.rooms

	-- Set up camera
	self.camera = MOAICamera2D.new()
	mainLayer:setCamera( self.camera )
	physicsLayer:setCamera( self.camera )

	local cameraFitter = MOAICameraFitter2D.new()	
	cameraFitter:setViewport( mainLayer.viewport )
	cameraFitter:setCamera( self.camera )
	cameraFitter:start()
	self.camera.fitter = cameraFitter
	
	-- Set up the first room
	self:MoveToRoom()
	
	-- Add an anchor for the camera
	local anchor = MOAICameraAnchor2D.new()
	anchor:setParent(self.roomGrid)
	anchor:setRect(-RoomDimensionsWorld[1] / 2, -RoomDimensionsWorld[2] / 2, RoomDimensionsWorld[1] / 2, RoomDimensionsWorld[2] / 2)
	cameraFitter:insertAnchor(anchor)

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
	--print(MOAISim.getPerformance())
	self.world:Update()
	if self.world.player.dead then
		self:Restart()
	end
	
	if self.shouldMoveRoom then
		self:MoveToRoom()
		self.shouldMoveRoom = false
	end
	
	if self.world.roomFinished then
		self:RoomFinished()
		self.world.roomFinished = false
	end
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Game:RoomFinished()
	self:OpenDoors()
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Game:MoveToRoom()
	self.currentRoom = Room()
	table.insert(self.rooms, self.currentRoom)

	self:ClearRoom()
	self:PopulateRoom()
	
	self.roomFinished = false
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Game:ClearRoom()
	self.world:Clear()
	
	--[[
	MOAISim.reportHistogram()
	MOAISim.reportLeaks()
	--]]
	
	MOAISim.forceGC()
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Game:PopulateRoom()
	self:CloseDoors()
	local roomNumber = #self.rooms
	local startPositiion = { 0, 0 }

	if self.usedDoor then				
		if self.usedDoor.name == "Top" then
			local startDoor = "Bottom"
			startPositiion = { self.doors[startDoor].body:getPosition() }
			startPositiion[2] = startPositiion[2] + TileDimensions[2]
			
		elseif self.usedDoor.name == "Right" then
			local startDoor = "Left"
			startPositiion = { self.doors[startDoor].body:getPosition() }
			startPositiion[1] = startPositiion[1] + TileDimensions[1]

		elseif self.usedDoor.name == "Bottom" then
			local startDoor = "Top"
			startPositiion = { self.doors[startDoor].body:getPosition() }
			startPositiion[2] = startPositiion[2] - TileDimensions[2]

		else
			local startDoor = "Right"
			startPositiion = { self.doors[startDoor].body:getPosition() }
			startPositiion[1] = startPositiion[1] - TileDimensions[1]

		end

		self.world.player.body:setTransform(unpack(startPositiion))
		self.world.player.controller:Reset()
	end
	
		-- In the first room spawn a key and no enemies
	if roomNumber == 1 then
		local keyPosition = startPositiion
		keyPosition[2] = keyPosition[2] + 300
		self.world:SpawnKey( keyPosition )
	else

		for enemyIndex, enemyType in ipairs(SpawnList[roomNumber]) do
			self:CreateEnemy(enemyType)
		end

	end
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Game:CloseDoors()
	-- Close all doors
	local roomGrid = self.roomGrid.grid
	for doorName, door in pairs(self.doors) do
		-- Change the tiles
		for doorTileIndex, doorTile in ipairs(door.tiles) do
			roomGrid:setTile( doorTile[1], doorTile[2], 2 )			
		end

		door.body:setActive(false)
	end
	
	
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Game:OpenDoors()
	-- Open all doors
	local roomGrid = self.roomGrid.grid
	for doorName, door in pairs(self.doors) do
		-- Only open the top door
		if doorName == "Top" then
			-- Change the tiles
			for doorTileIndex, doorTile in ipairs(door.tiles) do
				roomGrid:setTile( doorTile[1], doorTile[2], 3 )			
			end
			
			door.body:setActive(true)
		end		
	end
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Game:Restart()
	self.world.player:Reset()
	
	self.currentRoom = nil
	self.rooms = {}

	self.world.rooms = self.rooms
	
	-- Start on the 1st room again
	self:MoveToRoom()
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Game:CreateEnemy(type)
	local layer = self.layer
	
	local tilePosition = 
	{
		math.random( 3, RoomDimensionsTiles[1] - 3 ),
		math.random( RoomDimensionsTiles[2] / 2, RoomDimensionsTiles[2] - 3 )
	}
	
	-- Round the tile up to the nearest even number
	tilePosition[1] = tilePosition[1] + (tilePosition[1] % 2)
	tilePosition[2] = tilePosition[2] + (tilePosition[2] % 2)

	local position = self:TileToWorldPosition(tilePosition)
	
	local enemyInfo = Enemy.Types[type]
	local enemy = self.world:CreateEnemy(position, enemyInfo)
end


--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Game:TileToWorldPosition(position)
	local worldPosition =
	{
		((position[1] + 0.5) * TileDimensions[1]) - (RoomDimensionsWorld[1] / 2),
		((position[2] + 0.5) * TileDimensions[2]) - (RoomDimensionsWorld[2] / 2)
	}
	
	return worldPosition
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Game:WorldToTilePosition()
	
end

--------------------------------------------------------------------------------
-- Set up background image
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

	-- Setup the room grid
	local grid = MOAIGrid.new ()
	grid:initRectGrid( RoomDimensionsTiles[1], RoomDimensionsTiles[2], TileDimensions[1], TileDimensions[2], 0, 0, 1, 1 )

	local tileDeck = TexturePacker:Load(GRAPHICS_DIR .. "roomTiles.lua", GRAPHICS_DIR .. "roomTiles.png", { x0 = 0, y0 = 0, x1 = 1, y1 = 1 })
	local roomGridProp = MOAIProp2D.new()
	roomGridProp:setDeck( tileDeck )
	roomGridProp:setGrid( grid )
	roomGridProp.grid = grid
	
	for tileX = 1, RoomDimensionsTiles[1] do
		for tileY = 1, RoomDimensionsTiles[2] do
			if (tileX == 1 or tileX == RoomDimensionsTiles[1]) or (tileY == 1 or tileY == RoomDimensionsTiles[2]) then
				grid:setTile( tileX, tileY,	6 )
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
	
	-- Create wall physics
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
	
	-- Create door tiles
	local doorSize = 4
	
	self.doors = {}
	for wallIndex, wallPosition in ipairs(wallPositions) do
		
		local door = self:CreateDoor(wallIndex, wallPosition, doorSize)
		door.tiles = {}

--[[
		if wallIndex == 1 then
			-- Left door
			for doorOffsetIndex = 1, doorSize do
				local tileYPos = (RoomDimensionsTiles[2] / 2) - (doorSize / 2) + doorOffsetIndex
				local tilePosition = { 1, tileYPos }
				grid:setTile( tilePosition[1], tilePosition[2], 2 )
				
				table.insert(door.tiles, tilePosition)
				door.name = 'Left'
			end
		else --]] if wallIndex == 2 then
			-- Top door
			for doorOffsetIndex = 1, doorSize do
				local tileXPos = (RoomDimensionsTiles[1] / 2) - (doorSize / 2) + doorOffsetIndex
				local tilePosition = { tileXPos, RoomDimensionsTiles[2] }
				grid:setTile( tilePosition[1], tilePosition[2], 2 )
				
				table.insert(door.tiles, tilePosition)
				door.name = 'Top'
			end
		else--[[if wallIndex == 3 then
			-- Right door
			for doorOffsetIndex = 1, doorSize do
				local tileYPos = (RoomDimensionsTiles[2] / 2) - (doorSize / 2) + doorOffsetIndex
				local tilePosition = { RoomDimensionsTiles[1], tileYPos }
				grid:setTile( tilePosition[1], tilePosition[2], 2 )
				
				table.insert(door.tiles, tilePosition)
				door.name = 'Right'
			end
		else--]]
			-- Bottom door
			for doorOffsetIndex = 1, doorSize do
				local tileXPos = (RoomDimensionsTiles[1] / 2) - (doorSize / 2) + doorOffsetIndex
				local tilePosition = { tileXPos, 1 }
				grid:setTile( tilePosition[1], tilePosition[2], 2 )
				
				table.insert(door.tiles, tilePosition)
				door.name = 'Bottom'
			end
		end

		self.doors[door.name] = door

	end

end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Game:CreateDoor(wallIndex, wallPosition, doorSize)
	local door = {}
	
	-- Create door physics
	function door.onCollide( event, fixtureA, fixtureB, arbiter )
		local bodyA = fixtureA:getBody()
		local bodyB = fixtureB:getBody()

		local objectA = bodyA.owner
		local objectB = bodyB.owner

		if event == MOAIBox2DArbiter.BEGIN then
			if objectA == door and objectB == self.world.player then
				self.shouldMoveRoom = true
				self.usedDoor = door
			end
		end
	end

	door.body = self.physicsWorld:addBody( MOAIBox2DBody.STATIC )
	local doorDimensions = {}
	if wallIndex % 2 == 1 then
		doorDimensions = { TileDimensions[1], TileDimensions[2] * doorSize }
	else
		doorDimensions = { TileDimensions[1] * doorSize, TileDimensions[2] }
	end

	local fixture = door.body:addRect( -doorDimensions[1] / 2, -doorDimensions[2] / 2, doorDimensions[1] / 2, doorDimensions[2] / 2 )
	fixture:setFilter( CollisionFilters.Category.Environment, CollisionFilters.Mask.Environment )
	fixture:setCollisionHandler( door.onCollide, MOAIBox2DArbiter.BEGIN + MOAIBox2DArbiter.END )

	door.body:setTransform(wallPosition[1], wallPosition[2], 0)
	door.body:setActive(false)
	door.body.owner = door
	
	return door
end


return Game