local CollisionFilters = require("World/CollisionFilters")

local Projectile = Class()

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------
function Projectile:Constructor(world, owner, initialDirection)
	self.initialDirection = initialDirection
	self.owner = owner
	
	local lifeTime = 2
	local lifeTimer = MOAITimer.new()
	lifeTimer:setSpan(lifeTime)
	lifeTimer:setListener(MOAITimer.EVENT_TIMER_END_SPAN,
		function()
			self.dead = true
		end)
	lifeTimer:start()
	
	self.damage = 5
	
	self:Initialise(world)
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Projectile:Initialise(world)
	local layer = world.layer
	local physicsWorld = world.physicsWorld

	-- dtreadgold: Set up prop and physics
	local playerQuad = MOAIGfxQuad2D.new ()
	playerQuad:setTexture ( GRAPHICS_DIR .. "p1.png" )
	local size = { 10, 14 }
	playerQuad:setRect ( -size[1] / 2, -size[2] / 2, size[1] / 2, size[2] / 2 )

	self.prop = MOAIProp2D.new()
	self.prop:setDeck ( playerQuad )
	layer:insertProp ( self.prop )
	
	local worldBody = physicsWorld:addBody ( MOAIBox2DBody.DYNAMIC )
	worldBody:setBullet(true)
	local fixture = worldBody:addCircle( 0, 0, size[1] / 2 )
	--local fixture = worldBody:addRect( -size[1] / 2, -size[2] / 2, size[1] / 2, size[2] / 2 )
	fixture:setSensor(true)
	
	function onCollide( event, fixtureA, fixtureB, arbiter )
		local bodyA = fixtureA:getBody()
		local bodyB = fixtureB:getBody()

		local objectA = bodyA.owner
		local objectB = bodyB.owner

		if event == MOAIBox2DArbiter.BEGIN then
			if objectA == self and objectB ~= self.owner then
				self.dead = true
			end
		end
	end
	fixture:setCollisionHandler( onCollide, MOAIBox2DArbiter.BEGIN + MOAIBox2DArbiter.END )
	fixture:setFilter( CollisionFilters.Category.EnemyProjectiles, CollisionFilters.Mask.EnemyProjectiles )
	
	self.prop:setAttrLink( MOAIProp2D.INHERIT_LOC, worldBody, MOAIProp2D.TRANSFORM_TRAIT )
	worldBody.owner = self
	self.body = worldBody
	
	local moveSpeed = 500
	local impulse = self.initialDirection
	self.body:applyLinearImpulse(impulse[1] * moveSpeed, impulse[2] * moveSpeed)
	
	self.prop:setRot( math.deg(math.atan2(impulse[2], impulse[1])) + 90 )
	
	self.body:setTransform(self.owner.body:getPosition())
end

return Projectile