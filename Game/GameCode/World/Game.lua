local FileIO 			= require("World/FileIO")
local Room 				= require("World/Room")
local TexturePacker 	= require("Util/TexturePacker")
local Player			= require("World/Player")
local Enemy				= require("World/Enemy")
local CollisionFilters 	= require("World/CollisionFilters")
local World				= require("World/World")
local Key				= require("World/Key")

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

	self.layer = mainLayer
	self.physicsWorld = physicsWorld
	
	self.world = World(mainLayer, physicsWorld)
	self.rooms = self.world.rooms

	-- dtreadgold: Set up camera
	self.camera = MOAICamera2D.new()
	mainLayer:setCamera( self.camera )
	physicsLayer:setCamera( self.camera )

	local cameraFitter = MOAICameraFitter2D.new()	
	cameraFitter:setViewport( mainLayer.viewport )
	cameraFitter:setCamera( self.camera )
	cameraFitter:start()
	self.camera.fitter = cameraFitter
	
	self:CreateBackground()
	self:CreateRoomGrid()
	
	self.player = Player(self.world)
	self.world.player = self.player
	
	-- dtreadgold: Set up the first room
	self:MoveToRoom()
	
	-- dtreadgold: Add an anchor for the camera
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
	print(MOAISim.getPerformance())
	self.world:Update()
	self.player:Update()
	if self.player.dead then
		self:Restart()
	end
	
	-- dtreadgold: Update all enemies
	for enemyIndex, enemy in ipairs(self.world.enemies) do
		enemy:Update()
		
		if enemy.dead then
			-- dtreadgold: Add the points to the player
			self.player:AddPoints(enemy.points)
			
			-- dtreadgold: If this is the last enemy then spawn the key
			if #self.world.enemies == 1 then
				self:SpawnKey( {enemy.body:getPosition()} )
			end

			enemy:Deactivate()
			self.world.objectPools.enemy:FreeObject(enemy)
			table.remove(self.world.enemies, enemyIndex)
		end
	end
	
	-- dtreadgold: Check for the key being picked up
	if self.key and self.key.dead then
		-- dtreadgold: Add the points to the player
		self.player:AddPoints(self.key.points)

		self.key:Destroy()
		self.key = nil
		
		self:RoomFinished()		
	end
	
	if self.shouldMoveRoom then
		self:MoveToRoom()
		self.shouldMoveRoom = false
	end
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Game:SpawnKey(position)
	self.key = Key(self, position)
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

		self.player.body:setTransform(unpack(startPositiion))
		self.player.controller:Reset()
	end
	
		-- dtreadgold: In the first room spawn a key and no enemies
	if roomNumber == 1 then
		local keyPosition = startPositiion
		keyPosition[2] = keyPosition[2] + 300
		self:SpawnKey( keyPosition )
	else

		local enemyPoints = roomNumber
		while enemyPoints > 0 do
			enemyPoints = self:CreateEnemy(enemyPoints)
		end

	end
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Game:CloseDoors()
	-- dtreadgold: Close all doors
	local roomGrid = self.roomGrid.grid
	for doorName, door in pairs(self.doors) do
		-- dtreadgold: Change the tiles
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
	-- dtreadgold: Open all doors
	local roomGrid = self.roomGrid.grid
	for doorName, door in pairs(self.doors) do
		-- dtreadgold: Only open the top door
		if doorName == "Top" then
			-- dtreadgold: Change the tiles
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
	self.player:Reset()
	
	self.currentRoom = nil
	self.rooms = {}

	self.world.rooms = self.rooms
	
	-- dtreadgold: Start on the 1st room again
	self:MoveToRoom()
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Game:CreateEnemy(pointsRemaining)
	local layer = self.layer
	
	local potentialEnemies = {}
	local maxPoints = 0
	for enemyName, enemyInfo in pairs(Enemy.Types) do
		if enemyInfo.points <= pointsRemaining then
			table.insert(potentialEnemies, enemyInfo)
			maxPoints = math.max(maxPoints, enemyInfo.points)
		end
	end
	
	-- dtreadgold: Make sure the list is only filled with enemys of max points
	local enemies = {}
	for enemyIndex, enemyInfo in ipairs(potentialEnemies) do
		if enemyInfo.points == maxPoints then
			table.insert(enemies, enemyInfo)
		end
	end

	local tilePosition = 
	{
		math.random( 3, RoomDimensionsTiles[1] - 3 ),
		math.random( RoomDimensionsTiles[2] / 2, RoomDimensionsTiles[2] - 3 )
	}
	
	-- dtreadgold: Round the tile up to the nearest even number
	tilePosition[1] = tilePosition[1] + (tilePosition[1] % 2)
	tilePosition[2] = tilePosition[2] + (tilePosition[2] % 2)

	local position = self:TileToWorldPosition(tilePosition)
	
	local enemyInfo = enemies[math.random(1, #enemies)]	
	local enemy = self.world:CreateEnemy(position, enemyInfo)
	
	return pointsRemaining - enemyInfo.points
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

	-- dtreadgold: Setup the room grid
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
	
	self.doors = {}
	for wallIndex, wallPosition in ipairs(wallPositions) do
		
		local door = self:CreateDoor(wallIndex, wallPosition, doorSize)
		door.tiles = {}

--[[
		if wallIndex == 1 then
			-- dtreadgold: Left door
			for doorOffsetIndex = 1, doorSize do
				local tileYPos = (RoomDimensionsTiles[2] / 2) - (doorSize / 2) + doorOffsetIndex
				local tilePosition = { 1, tileYPos }
				grid:setTile( tilePosition[1], tilePosition[2], 2 )
				
				table.insert(door.tiles, tilePosition)
				door.name = 'Left'
			end
		else --]] if wallIndex == 2 then
			-- dtreadgold: Top door
			for doorOffsetIndex = 1, doorSize do
				local tileXPos = (RoomDimensionsTiles[1] / 2) - (doorSize / 2) + doorOffsetIndex
				local tilePosition = { tileXPos, RoomDimensionsTiles[2] }
				grid:setTile( tilePosition[1], tilePosition[2], 2 )
				
				table.insert(door.tiles, tilePosition)
				door.name = 'Top'
			end
		else--[[if wallIndex == 3 then
			-- dtreadgold: Right door
			for doorOffsetIndex = 1, doorSize do
				local tileYPos = (RoomDimensionsTiles[2] / 2) - (doorSize / 2) + doorOffsetIndex
				local tilePosition = { RoomDimensionsTiles[1], tileYPos }
				grid:setTile( tilePosition[1], tilePosition[2], 2 )
				
				table.insert(door.tiles, tilePosition)
				door.name = 'Right'
			end
		else--]]
			-- dtreadgold: Bottom door
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
	
	-- dtreadgold: Create door physics
	function door.onCollide( event, fixtureA, fixtureB, arbiter )
		local bodyA = fixtureA:getBody()
		local bodyB = fixtureB:getBody()

		local objectA = bodyA.owner
		local objectB = bodyB.owner

		if event == MOAIBox2DArbiter.BEGIN then
			if objectA == door and objectB == self.player then
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