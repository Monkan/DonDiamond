local CollisionFilters = require("World/CollisionFilters")

local Projectile = Class()

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------
function Projectile:Constructor(world)
	self.world = world

	-- dtreadgold: Set up prop and physics
	local quad = MOAIGfxQuad2D.new ()
	quad:setTexture ( GRAPHICS_DIR .. "projectile.png" )
	local size = { 10, 14 }
	quad:setRect ( -size[1] / 2, -size[2] / 2, size[1] / 2, size[2] / 2 )

	self.prop = MOAIProp2D.new()
	self.prop:setDeck ( quad )
	self.size = size
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Projectile:Activate(owner, direction, damage)
	self.initialDirection = direction
	self.owner = owner
	self.faction = owner.faction
	self.dead = false
	
	local lifeTime = 2
	local lifeTimer = MOAITimer.new()
	lifeTimer:setSpan(lifeTime)
	lifeTimer:setListener(MOAITimer.EVENT_TIMER_END_SPAN,
		function()
			self.dead = true
		end)
	lifeTimer:start()
	self.lifeTimer = lifeTimer
	
	self.damage = damage

	local world = self.world
	local layer = world.layer

	-- dtreadgold: Set up prop and physics
	layer:insertProp ( self.prop )
	self:CreatePhysics(world.physicsWorld)

	local moveSpeed = 500
	local impulse = self.initialDirection
	self.body:applyLinearImpulse(impulse[1] * moveSpeed, impulse[2] * moveSpeed)	
	self.prop:setRot( math.deg(math.atan2(impulse[2], impulse[1])) + 90 )	
	self.body:setTransform(self.owner.body:getPosition())
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Projectile:Deactivate()
	local world = self.world
	local layer = world.layer

	self.lifeTimer:stop()
	self.body:destroy()
	self.body = nil
	layer:removeProp( self.prop )
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Projectile:CreatePhysics(physicsWorld)
	local worldBody = physicsWorld:addBody ( MOAIBox2DBody.DYNAMIC )
	worldBody:setBullet(true)
	local fixture = worldBody:addCircle( 0, 0, self.size[1] / 2 )
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
	
	if self.faction == "Good" then
		fixture:setFilter( CollisionFilters.Category.FriendlyProjectiles, CollisionFilters.Mask.FriendlyProjectiles )
	else
		fixture:setFilter( CollisionFilters.Category.EnemyProjectiles, CollisionFilters.Mask.EnemyProjectiles )
	end
	
	self.prop:setAttrLink( MOAIProp2D.INHERIT_LOC, worldBody, MOAIProp2D.TRANSFORM_TRAIT )
	worldBody.owner = self
	self.body = worldBody
end

return Projectile