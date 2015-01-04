local Projectile 		= require("World/Projectile")
local TexturePacker 	= require("Util/TexturePacker")
local CollisionFilters 	= require("World/CollisionFilters")

local Enemy = Class()

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------
function Enemy:Constructor(world)
	self.state = "Attacking"
	self.health = 20
	self.faction = "Bad"
	
	self.world = world
	self:Initialise(world)
	
	local fireTimer = MOAITimer.new()
	fireTimer:setSpan(2)
	fireTimer:setMode(MOAITimer.LOOP)
	fireTimer:setListener(MOAITimer.EVENT_TIMER_LOOP,
		function()
			self.canFire = true
		end)
	fireTimer:start()
	
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
	
	--[[
	local spinTimer = MOAITimer.new()
	spinTimer:setSpan(1)
	spinTimer:setMode(MOAITimer.LOOP)
	spinTimer:setListener(MOAITimer.EVENT_TIMER_LOOP,
		function()
			local spinDirection = math.random(-1, 1)
			if spinDirection <= 0 then
				spinDirection = -1
			else
				spinDirection = 1
			end

			self.prop:moveRot(spinDirection * 2000, 5)
		end)
	spinTimer:start()
	--]]

end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Enemy:Initialise(world)
	local layer = world.layer
	local physicsWorld = world.physicsWorld
	
	-- dtreadgold: Set up prop and physics
	--local deck = 
	local playerQuad = MOAIGfxQuad2D.new ()
	playerQuad:setTexture ( GRAPHICS_DIR .. "enemy1.png" )
	local size = { 48, 34 }
	playerQuad:setRect ( -size[1] / 2, -size[2] / 2, size[1] / 2, size[2] / 2 )

	self.prop = MOAIProp2D.new()
	self.prop:setDeck ( playerQuad )
	layer:insertProp ( self.prop )
	
	local worldBody = physicsWorld:addBody ( MOAIBox2DBody.DYNAMIC )
	local fixture = worldBody:addCircle( 0, 0, size[1] / 2 )
	--local fixture = worldBody:addRect( -size[1] / 2, -size[2] / 2, size[1] / 2, size[2] / 2 )
	fixture:setFilter( CollisionFilters.Category.Enemy, CollisionFilters.Mask.Enemy )
	
	function onCollide( event, fixtureA, fixtureB, arbiter )
		local bodyA = fixtureA:getBody()
		local bodyB = fixtureB:getBody()

		local objectA = bodyA.owner
		local objectB = bodyB.owner

		if event == MOAIBox2DArbiter.BEGIN then
			if objectA == self and objectB and objectB.owner ~= self then
				-- If we have collided with something that does damage
				if objectB.damage then
					self.health = self.health - objectB.damage
					if self.health < 0 then
						self.dead = true
					end
				end
			end
		end
	end
	fixture:setCollisionHandler( onCollide, MOAIBox2DArbiter.BEGIN + MOAIBox2DArbiter.END )
	
	self.prop:setAttrLink(MOAITransform.INHERIT_TRANSFORM, worldBody, MOAITransform.TRANSFORM_TRAIT)
	worldBody.owner = self

	self.body = worldBody
	self.body:setLinearDamping(3)
	self.body:resetMassData()
	
	self.layer = layer
	self.physicsWorld = physicsWorld
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Enemy:Update()
	local player = self.world.player

	local moveSpeed = 20
	local minDistanceFromPlayer = 200
	local maxMoveSpeed = 100
	
	-- dtreadgold: Clamp the movement speed to max move speed
	local velocity = { self.body:getLinearVelocity() }
	if math.lengthSqrd(velocity) > maxMoveSpeed * maxMoveSpeed then
		velocity = math.normalise(velocity)
		velocity = math.mulVecScl(velocity, maxMoveSpeed)
		
		self.body:setLinearVelocity(unpack(velocity))
	end

	local impuse = { 0, 0 }
	local position = { self.body:getPosition() }
	local playerPosition = { player.body:getPosition() }
	local directionToPlayer = math.subVec(playerPosition, position)
	local distanceToPlayer = math.length(directionToPlayer)
	directionToPlayer = math.divVecScl(directionToPlayer, distanceToPlayer)	
	
	if self.state == "Attacking" then

		if distanceToPlayer < minDistanceFromPlayer then		
			self.state = "Still"
		else
			impuse = math.mulVecScl(directionToPlayer, moveSpeed)
		end

	elseif self.state == "Still" then
		
		if distanceToPlayer > minDistanceFromPlayer * 2 then		
			self.state = "Attacking"
		elseif distanceToPlayer < minDistanceFromPlayer / 2 then
			self.state = "Retreating"
		end

	elseif self.state == "Retreating" then
		
		if distanceToPlayer > minDistanceFromPlayer * 2 then		
			self.state = "Attacking"
		else
			impuse = math.mulVecScl(directionToPlayer, -moveSpeed)
		end

	end

	self.body:applyLinearImpulse(impuse[1], impuse[2])
	
	if self.canFire then
		self.canFire = false
		self:Fire(directionToPlayer)
	end
	
	--[[
	if math.lengthSqrd(velocity) > 0 then
		local position = { self.body:getPosition() }
		self.body:setTransform( position[1], position[2], math.deg(math.atan2(velocity[2], velocity[1])) + 90 )
	end
	--]]

end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Enemy:Fire(directionToPlayer)
	
	local projectile = Projectile(self.world, self, directionToPlayer)
	table.insert(self.world.projectiles, projectile)
end


return Enemy