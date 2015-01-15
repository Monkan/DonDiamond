local Projectile 		= require("World/Projectile")
local TexturePacker 	= require("Util/TexturePacker")
local CollisionFilters 	= require("World/CollisionFilters")

local Enemy = Class()

--------------------------------------------------------------------------------
-- Types
--------------------------------------------------------------------------------
Enemy.Types = 
{	
	RedSmall	= require("World/Enemies/EnemyRedSmall"),
	Red 		= require("World/Enemies/EnemyRed"),
	
	GreenSmall	= require("World/Enemies/EnemyGreenSmall"),
	Green 		= require("World/Enemies/EnemyGreen"),
	
	BlueSmall	= require("World/Enemies/EnemyBlueSmall"),
	Blue 		= require("World/Enemies/EnemyBlue"),
}

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------
function Enemy:Constructor(world, enemyInfo)
	self.state = "Attacking"
	self.health = enemyInfo.health
	self.faction = "Bad"
	self.enemyInfo = enemyInfo
	
	self.world = world
	self:Initialise(world)
	
	local fireTimer = MOAITimer.new()
	fireTimer:setSpan(enemyInfo.fireRate)
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
	local deck = MOAIGfxQuad2D.new()
	deck:setTexture ( GRAPHICS_DIR .. self.enemyInfo.texture )
	local size = { 48, 34 }
	deck:setRect( -size[1] / 2, -size[2] / 2, size[1] / 2, size[2] / 2 )

	self.prop = MOAIProp2D.new()
	self.prop:setDeck( deck )
	layer:insertProp( self.prop )
	
	-- dtreadgold: Add the prop for the eye
	local eyeDeck, names = TexturePacker:Load(GRAPHICS_DIR .. "enemyEyes.lua", GRAPHICS_DIR .. "enemyEyes.png")
	eyeDeck.names = names

	self.eyeProp = MOAIProp2D.new()
	self.eyeProp:setDeck( eyeDeck )
	self.eyeProp.deck = eyeDeck
	--layer:insertProp ( self.eyeProp )
	self.eyeProp:setLoc(0, 0)	
	self.eyeProp:setAttrLink(MOAITransform.INHERIT_TRANSFORM, self.prop, MOAITransform.TRANSFORM_TRAIT)
	
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
					if self.health <= 0 then
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
	local maxMoveSpeed = self.enemyInfo.maxMoveSpeed
	
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
		
		if distanceToPlayer > minDistanceFromPlayer * 1.5 then		
			self.state = "Attacking"
		elseif distanceToPlayer < minDistanceFromPlayer / 1.5 then
			self.state = "Retreating"
		end

	elseif self.state == "Retreating" then
		
		if distanceToPlayer > minDistanceFromPlayer * 1.5 then		
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
	
	if self.enemyInfo.fireType == "Radius" then
		self:FireRadius()
	elseif self.enemyInfo.fireType == "AtPlayer" then
		self:FireAtPlayer(directionToPlayer)
	end
	
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Enemy:FireAtPlayer(directionToPlayer)
	
	local projectile = Projectile(self.world, self, directionToPlayer, self.enemyInfo.projectileDamage)
	table.insert(self.world.projectiles, projectile)
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Enemy:FireRadius()
	
	local numProjectiles = self.enemyInfo.numberOfProjectiles
	local angleStep = 360 / numProjectiles
	
	local startAngleOffset = 0
	if self.enemyInfo.randomOffset > 0 then
		startAngleOffset = math.random(0, (360 / self.enemyInfo.randomOffset) - 1) * self.enemyInfo.randomOffset
	end
	local direction = { 1, 0 }
	direction = math.rotateVecAngle(direction, startAngleOffset)

	for projectileIndex = 1, numProjectiles do
		local projectile = Projectile(self.world, self, direction, self.enemyInfo.projectileDamage)
		table.insert(self.world.projectiles, projectile)
		
		direction = math.rotateVecAngle(direction, angleStep)
	end
	
end


return Enemy