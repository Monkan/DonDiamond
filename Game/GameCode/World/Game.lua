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
	
	math.randomseed(MOAISim.getDeviceTime())
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
	
	if self.shouldMoveRoom then
		self:MoveToRoom()
		self.shouldMoveRoom = false
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
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Game:ClearRoom()
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
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Game:PopulateRoom()
	self:CloseDoors()

	local enemyPoints = #self.rooms
	while enemyPoints > 0 do
		enemyPoints = self:CreateEnemy(enemyPoints)
	end
	
	if self.usedDoor then
		local startPositiion = { 0, 0 }		
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
		-- dtreadgold: Change the tiles
		for doorTileIndex, doorTile in ipairs(door.tiles) do
			roomGrid:setTile( doorTile[1], doorTile[2], 3 )			
		end

		door.body:setActive(true)
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
	for enemyName, enemyInfo in pairs(Enemy.Types) do
		if enemyInfo.points <= pointsRemaining then
			table.insert(potentialEnemies, enemyInfo)
		end
	end

	local enemyInfo = potentialEnemies[math.random(1, #potentialEnemies)]
	local enemy = Enemy(self.world, enemyInfo)
	table.insert(self.enemies, enemy)
	
	local position =
	{
		math.random( (-RoomDimensionsWorld[1] / 2) + TileDimensions[1], (RoomDimensionsWorld[1] / 2) - TileDimensions[1] ),
		math.random( (-RoomDimensionsWorld[2] / 2) + TileDimensions[2], (RoomDimensionsWorld[2] / 2) - TileDimensions[2] ),
	}
	enemy.body:setTransform(position[1], position[2], 0)
	
	return pointsRemaining - enemyInfo.points
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
	roomGridProp.grid = grid
	
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
	
	self.doors = {}
	for wallIndex, wallPosition in ipairs(wallPositions) do
		local door = self:CreateDoor(wallIndex, wallPosition, doorSize)
		door.tiles = {}
		local doorName = ''

		if wallIndex == 1 then
			-- dtreadgold: Left door
			for doorOffsetIndex = 1, doorSize do
				local tileYPos = (roomDimensionsTiles[2] / 2) - (doorSize / 2) + doorOffsetIndex
				local tilePosition = { 1, tileYPos }
				grid:setTile( tilePosition[1], tilePosition[2], 2 )
				
				table.insert(door.tiles, tilePosition)
				door.name = 'Left'
			end
		elseif wallIndex == 2 then
			-- dtreadgold: Top door
			for doorOffsetIndex = 1, doorSize do
				local tileXPos = (roomDimensionsTiles[1] / 2) - (doorSize / 2) + doorOffsetIndex
				local tilePosition = { tileXPos, roomDimensionsTiles[2] }
				grid:setTile( tilePosition[1], tilePosition[2], 2 )
				
				table.insert(door.tiles, tilePosition)
				door.name = 'Top'
			end
		elseif wallIndex == 3 then
			-- dtreadgold: Right door
			for doorOffsetIndex = 1, doorSize do
				local tileYPos = (roomDimensionsTiles[2] / 2) - (doorSize / 2) + doorOffsetIndex
				local tilePosition = { roomDimensionsTiles[1], tileYPos }
				grid:setTile( tilePosition[1], tilePosition[2], 2 )
				
				table.insert(door.tiles, tilePosition)
				door.name = 'Right'
			end
		else
			-- dtreadgold: Bottom door
			for doorOffsetIndex = 1, doorSize do
				local tileXPos = (roomDimensionsTiles[1] / 2) - (doorSize / 2) + doorOffsetIndex
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