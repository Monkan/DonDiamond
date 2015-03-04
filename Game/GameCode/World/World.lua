local FileIO 			= require("World/FileIO")
local Room 				= require("World/Room")
local TexturePacker 	= require("Util/TexturePacker")
local Player			= require("World/Player")
local Enemy				= require("World/Enemy")
local CollisionFilters 	= require("World/CollisionFilters")
local ObjectPool	 	= require("World/ObjectPool")
local Projectile	 	= require("World/Projectile")
local Pickup			= require("World/Pickup")

local World = Class()

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------
function World:Constructor(mainLayer, physicsWorld)
	self.layer = mainLayer
	self.physicsWorld = physicsWorld
	
	self.enemies = {}
	self.projectiles = {}
	self.pickups = {}
	self.rooms = {}
	
	self.objectPools = {}
	self.objectPools.projectile = ObjectPool(self, Projectile, 100)
	self.objectPools.enemy = ObjectPool(self, Enemy, 5)
	self.objectPools.pickup = ObjectPool(self, Pickup, 10)
	
	self.player = Player(self)
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

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function World:CreateProjectile(owner, initialDirection, damage)
	local projectile = self.objectPools.projectile:GetFreeObject()
	projectile:Activate(owner, initialDirection, damage)
	table.insert(self.projectiles, projectile)
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function World:CreateEnemy(position, enemyInfo)
	local enemy = self.objectPools.enemy:GetFreeObject()
	enemy:Activate(position, enemyInfo)
	table.insert(self.enemies, enemy)
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function World:CreatePickup(position, objectInfo)
	local object = self.objectPools.pickup:GetFreeObject()
	object:Activate(position, objectInfo)
	table.insert(self.pickups, object)
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function World:ReleaseObject(object, objectType)
	object:Deactivate()
	self.objectPools[objectType]:FreeObject(object)
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function World:Update()
	-- Remove any dead projectiles
	for projectileIndex, projectile in ipairs(self.projectiles) do
		if projectile.dead then
			self:ReleaseObject(projectile, "projectile")
			table.remove(self.projectiles, projectileIndex)
		end
	end
	
	-- Update all enemies
	for enemyIndex, enemy in ipairs(self.enemies) do
		enemy:Update()
		
		if enemy.dead then
			-- Add the points to the player
			self.player:AddPoints(enemy.points)
			
			-- If this is the last enemy then spawn the key
			if #self.enemies == 1 then
				self:SpawnKey( {enemy.body:getPosition()} )
			else
				self:CreateRandomPickup( {enemy.body:getPosition()} )
			end

			self:ReleaseObject(enemy, "enemy")
			table.remove(self.enemies, enemyIndex)
		end
	end
	
	-- Remove any dead pickups
	for objectIndex, object in ipairs(self.pickups) do
		if object.dead then
			-- Add the points to the player
			self.player:AddPoints(object.points)

			self:ReleaseObject(object, "pickup")
			table.remove(self.pickups, objectIndex)
		end
	end
	
	self.player:Update()
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function World:SpawnKey(position)
	self.key = self:CreatePickup(position, Pickup.Types.Key)
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function World:CreateRandomPickup(position)
	local frequencyTotal = 0
	for typeName, typeInfo in pairs(Pickup.Types) do
		if typeInfo.frequency > 0 then
			frequencyTotal = frequencyTotal + typeInfo.frequency
		end
	end
	
	local randomFrequency = math.random(1, frequencyTotal)
	local cumulativeFrequency = 0
	local selectedType = nil
	for typeName, typeInfo in pairs(Pickup.Types) do
		if typeInfo.frequency > 0 then
			cumulativeFrequency = cumulativeFrequency + typeInfo.frequency
			if randomFrequency <= cumulativeFrequency then
				selectedType = typeName
				break
			end
		end
	end
	
	if not selectedType then
		return
	end

	self.key = self:CreatePickup(position, Pickup.Types[selectedType])
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function World:Clear()
	for enemyIndex, enemy in ipairs(self.enemies) do
		enemy:Deactivate()
		self.objectPools.enemy:FreeObject(enemy)
	end
	self.enemies = {}
	
	for projectileIndex, projectile in ipairs(self.projectiles) do
		projectile:Deactivate()
		self.objectPools.projectile:FreeObject(projectile)
	end
	self.projectiles = {}
	
	for objectIndex, object in ipairs(self.pickups) do
		object:Deactivate()
		self.objectPools.pickup:FreeObject(object)
	end
	self.pickups = {}
end

return World