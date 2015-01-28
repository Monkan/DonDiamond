local FileIO 			= require("World/FileIO")
local Room 				= require("World/Room")
local TexturePacker 	= require("Util/TexturePacker")
local Player			= require("World/Player")
local Enemy				= require("World/Enemy")
local CollisionFilters 	= require("World/CollisionFilters")
local ObjectPool	 	= require("World/ObjectPool")
local Projectile	 	= require("World/Projectile")

local World = Class()

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------
function World:Constructor(mainLayer, physicsWorld)
	self.layer = mainLayer
	self.physicsWorld = physicsWorld
	
	self.enemies = {}
	self.projectiles = {}
	self.rooms = {}
	
	self.objectPools = {}
	self.objectPools.projectile = ObjectPool(self, Projectile, 100)
	--self.objectPools.enemy = ObjectPool(self, Enemy, 10)
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
function World:CreateEnemy(position, enemyType)
	local enemy = self.objectPools.enemy:GetFreeObject()
	enemy:Activate(position, enemyType)
	table.insert(self.enemies, enemy)
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function World:Update()
	-- dtreadgold: Remove any dead projectiles
	for projectileIndex, projectile in ipairs(self.projectiles) do
		if projectile.dead then
			projectile:Deactivate()
			self.objectPools.projectile:FreeObject(projectile)
			table.remove(self.projectiles, projectileIndex)
		end
	end
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function World:Clear()
	for enemyIndex, enemy in ipairs(self.enemies) do
		enemy:Destroy()
		table.remove(self.enemies, enemyIndex)
	end
	
	for projectileIndex, projectile in ipairs(self.projectiles) do
		projectile:Deactivate()
		self.objectPools.projectile:FreeObject(projectile)
		table.remove(self.projectiles, projectileIndex)
	end
end

return World