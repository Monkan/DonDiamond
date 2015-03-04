local TexturePacker 	= require("Util/TexturePacker")
local CollisionFilters 	= require("World/CollisionFilters")

local Pickup = Class()

--------------------------------------------------------------------------------
-- Types
--------------------------------------------------------------------------------
Pickup.Types = 
{	
	Key				= require("World/Pickups/Key"),
	PointsSmall		= require("World/Pickups/PointsSmall"),
	PointsBig		= require("World/Pickups/PointsBig"),
	HealthSmall		= require("World/Pickups/HealthSmall"),
	HealthBig		= require("World/Pickups/HealthBig"),
}

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------
function Pickup:Constructor(world, pickupInfo)
	self.world = world
	self.faction = "Good"
	
	local deck, names = TexturePacker:Load(GRAPHICS_DIR .. "pickups.lua", GRAPHICS_DIR .. "pickups.png")
	deck.names = names
	self.prop = MOAIProp2D.new()
	self.prop:setDeck ( deck )
	self.prop.deck = deck
	
	local rotateAmount = 10
	self.spinDirection = math.random(-1, 1)
	if self.spinDirection <= 0 then
		self.spinDirection = -1
	else
		self.spinDirection = 1
	end
	
	self.onSpinStop = function()
		self.spinDirection = self.spinDirection * -1
		self.spin( self.spinDirection * (rotateAmount * 2) )
	end

	self.spin = function(rotation)
		local action = self.prop:moveRot( rotation, 0.5 )
		action:setListener( MOAIAction.EVENT_STOP, self.onSpinStop )
	end

	self.spin(self.spinDirection * rotateAmount)
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Pickup:CreatePhysics(physicsWorld)
	local bodyType = MOAIBox2DBody.DYNAMIC
	local worldBody = physicsWorld:addBody ( MOAIBox2DBody.STATIC )
	--local fixture = worldBody:addCircle( 0, 0, size[1] / 2 )
	local fixture = worldBody:addRect( -self.size[1] / 2, -self.size[2] / 2, self.size[1] / 2, self.size[2] / 2 )
	fixture:setFilter( CollisionFilters.Category.Pickup, CollisionFilters.Mask.Pickup )
	
	function onCollide( event, fixtureA, fixtureB, arbiter )
		local bodyA = fixtureA:getBody()
		local bodyB = fixtureB:getBody()

		local objectA = bodyA.owner
		local objectB = bodyB.owner
		
		if event == MOAIBox2DArbiter.BEGIN then
			if objectA == self and objectB then
				self.dead = true
				self.OnCollected(self.world)
			end
		end
	end
	fixture:setCollisionHandler( onCollide, MOAIBox2DArbiter.BEGIN + MOAIBox2DArbiter.END )
	fixture:setSensor(true)
	
	self.prop:setAttrLink(MOAITransform.INHERIT_TRANSFORM, worldBody, MOAITransform.TRANSFORM_TRAIT)
	worldBody.owner = self

	self.body = worldBody
	self.body:resetMassData()
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Pickup:Activate(position, pickupInfo)
	table.copy(pickupInfo, self)
	self.dead = false

	local layer = self.world.layer
	local physicsWorld = self.world.physicsWorld
	
	-- Set up prop and physics
	self.size = { 30, 30 }
	self.size[1] = self.size[1] * self.scale
	self.size[2] = self.size[2] * self.scale
	self.prop:setIndex( self.prop.deck.names[self.textures[1]] )
	
	self.prop:setScl(self.scale)
	layer:insertProp( self.prop )
	
	self:CreatePhysics(physicsWorld)
	self.body:setTransform(position[1], position[2], 0)
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Pickup:Deactivate()
	local world = self.world
	local layer = world.layer
	
	self.body:destroy()
	self.body = nil
	layer:removeProp(self.prop)
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Pickup:Destroy()
	self:Deactivate()
end


return Pickup