local TexturePacker 	= require("Util/TexturePacker")
local CollisionFilters 	= require("World/CollisionFilters")

local Key = Class()

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------
function Key:Constructor(world, position)
	self.faction = "Good"
	self.world = world
	
	self.points = 10
	
	local layer = world.layer
	local physicsWorld = world.physicsWorld
	
	-- dtreadgold: Set up prop and physics
	local texturePath = GRAPHICS_DIR .. "key.png"
	local texture = MOAITexture.new()
	texture:load( texturePath )
	local size = { texture:getSize() }
	local scale = 0.8
	size = math.mulVecScl(size, scale)
	
	local deck = MOAIGfxQuad2D.new()
	deck:setTexture( texturePath )
	deck:setRect( -size[1] / 2, -size[2] / 2, size[1] / 2, size[2] / 2 )

	self.prop = MOAIProp2D.new()
	self.prop:setDeck( deck )
	self.prop:setScl(scale)
	layer:insertProp( self.prop )
	
	local worldBody = physicsWorld:addBody ( MOAIBox2DBody.STATIC )
	--local fixture = worldBody:addCircle( 0, 0, size[1] / 2 )
	local fixture = worldBody:addRect( -size[1] / 2, -size[2] / 2, size[1] / 2, size[2] / 2 )
	fixture:setFilter( CollisionFilters.Category.Key, CollisionFilters.Mask.Key )
	
	function onCollide( event, fixtureA, fixtureB, arbiter )
		local bodyA = fixtureA:getBody()
		local bodyB = fixtureB:getBody()

		local objectA = bodyA.owner
		local objectB = bodyB.owner

		if event == MOAIBox2DArbiter.BEGIN then
			if objectA == self and objectB then
				self.dead = true
			end
		end
	end
	fixture:setCollisionHandler( onCollide, MOAIBox2DArbiter.BEGIN + MOAIBox2DArbiter.END )
	fixture:setSensor(true)
	
	self.prop:setAttrLink(MOAITransform.INHERIT_TRANSFORM, worldBody, MOAITransform.TRANSFORM_TRAIT)
	worldBody.owner = self

	self.body = worldBody
	self.body:setLinearDamping(3)
	self.body:resetMassData()
	self.body:setTransform(unpack(position))
	
	self.layer = layer
	self.physicsWorld = physicsWorld
	
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
function Key:Destroy()
	self.body:destroy()
	self.world.layer:removeProp(self.prop)
end

return Key