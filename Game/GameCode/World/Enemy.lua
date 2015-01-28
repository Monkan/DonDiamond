local Projectile 		= require("World/Projectile")
local TexturePacker 	= require("Util/TexturePacker")
local CollisionFilters 	= require("World/CollisionFilters")
local Weapon			= require("World/Weapon")

local Enemy = Class()

--------------------------------------------------------------------------------
-- Types
--------------------------------------------------------------------------------
Enemy.Types = 
{	
	RedSmall		= require("World/Enemies/EnemyRedSmall"),
	RedBig			= require("World/Enemies/EnemyRedBig"),
	RedBoss			= require("World/Enemies/EnemyRedBoss"),
	--RedKamikaze		= require("World/Enemies/EnemyRedKamikaze"),
	
	GreenSmall		= require("World/Enemies/EnemyGreenSmall"),
	GreenBig		= require("World/Enemies/EnemyGreenBig"),
	GreenBoss		= require("World/Enemies/EnemyGreenBoss"),
	--GreenKamikaze	= require("World/Enemies/EnemyGreenKamikaze"),
	
	BlueSmall		= require("World/Enemies/EnemyBlueSmall"),
	BlueBig			= require("World/Enemies/EnemyBlueBig"),
	BlueBoss		= require("World/Enemies/EnemyBlueBoss"),
	--BlueKamikaze	= require("World/Enemies/EnemyBlueKamikaze"),
}

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------
function Enemy:Constructor(world, enemyInfo)
	self.state = "Attacking"
	self.health = enemyInfo.health
	self.faction = "Bad"
	self.enemyInfo = enemyInfo
	self.blinkInterval = { min = 2, max = 5 }
	
	self.world = world
	self:Initialise(world)
	
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
	
	if self.enemyInfo.weapons then
		self.weapons = {}
		for weaponIndex, weaponData in ipairs(self.enemyInfo.weapons) do
			local weapon = Weapon(world, self, weaponData.projectileDamage)
			table.copy(weaponData, weapon)
			
			if weapon.fireType == "Spiral" then
				if weapon.direction then
					weapon.fireStep = weapon.direction * 20
				else
					local spinDirection = math.random(0, 1)
					if spinDirection == 0 then
						weapon.fireStep = 20
					else
						weapon.fireStep = -20
					end
				end
			end
			
			
			local fireTimer = MOAITimer.new()
			fireTimer:setSpan(weaponData.fireRate)
			fireTimer:setMode(MOAITimer.LOOP)
			fireTimer:setListener(MOAITimer.EVENT_TIMER_LOOP,
				function()
					weapon.canFire = true
				end)
			fireTimer:start()
			weapon.fireTimer = fireTimer
			
			table.insert(self.weapons, weapon)
		end
	end
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Enemy:Initialise(world)
	local layer = world.layer
	local physicsWorld = world.physicsWorld
	
	-- dtreadgold: Set up prop and physics
	local deck, names = TexturePacker:Load(GRAPHICS_DIR .. "enemies.lua", GRAPHICS_DIR .. "enemies.png")
	deck.names = names

	local size = { 80, 60 }
	size[1] = size[1] * self.enemyInfo.scale
	size[2] = size[2] * self.enemyInfo.scale

	self.prop = MOAIProp2D.new()
	self.prop:setDeck ( deck )
	self.prop:setIndex( deck.names[self.enemyInfo.textures[4]] )
	self.prop.deck = deck
	self.prop:setScl(self.enemyInfo.scale)
	layer:insertProp( self.prop )
	
	-- dtreadgold: Add the prop for the eye
	self.eyeProp = MOAIProp2D.new()
	self.eyeProp:setDeck ( deck )
	self.eyeProp.deck = deck
	layer:insertProp ( self.eyeProp )
	self.eyeProp:setLoc(0, 0)
	self.eyeProp:setAttrLink(MOAITransform.INHERIT_TRANSFORM, self.prop, MOAITransform.TRANSFORM_TRAIT)
	if math.random(2) == 1 then
		self.blinkImages =
		{
			"horizontaleye1.png",
			"horizontaleye2.png",
			"horizontaleye3.png"
		}
	else
		self.blinkImages =
		{
			"verticaleye1.png",
			"verticaleye2.png",
			"verticaleye3.png"
		}
	end
	
	self.blinkIndex = 1
	self.eyeProp:setIndex( deck.names[self.blinkImages[self.blinkIndex]] )
	--self:StartNextBlinkTimer()
	
	local bodyType = MOAIBox2DBody.DYNAMIC
	if self.enemyInfo.maxMoveSpeed > 0 then
		bodyType = MOAIBox2DBody.DYNAMIC
	else
		bodyType = MOAIBox2DBody.STATIC
	end

	local worldBody = physicsWorld:addBody ( bodyType )
	--local fixture = worldBody:addCircle( 0, 0, size[1] / 2 )
	local fixture = worldBody:addRect( -size[1] / 2, -size[2] / 2, size[1] / 2, size[2] / 2 )
	fixture:setFilter( CollisionFilters.Category.Enemy, CollisionFilters.Mask.Enemy )
	
	function onCollide( event, fixtureA, fixtureB, arbiter )
		local bodyA = fixtureA:getBody()
		local bodyB = fixtureB:getBody()

		local objectA = bodyA.owner
		local objectB = bodyB.owner

		if event == MOAIBox2DArbiter.BEGIN then
			if objectA == self and objectB and objectB.owner and objectB.owner.faction ~= self.faction then
				-- If we have collided with something that does damage
				if objectB.damage then
					self:ReduceHealth(objectB.damage)
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
function Enemy:ReduceHealth(amount)
	self.health = self.health - amount
	if self.health <= 0 then
		self.dead = true
	end
	
	-- dtreadgold: Set the correct image for the damage amount
	local healthProportion = self.health / self.enemyInfo.health
	if healthProportion < 0.25 then
		self.prop:setIndex( self.prop.deck.names[self.enemyInfo.textures[1]] )
	elseif healthProportion < 0.5 then
		self.prop:setIndex( self.prop.deck.names[self.enemyInfo.textures[2]] )
	elseif healthProportion < 0.75 then
		self.prop:setIndex( self.prop.deck.names[self.enemyInfo.textures[3]] )
	else
		self.prop:setIndex( self.prop.deck.names[self.enemyInfo.textures[4]] )
	end
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Enemy:StartNextBlinkTimer()
	if self.blinkTimer then
		self.blinkTimer:stop()
		self.blinkTimer = nil
	end

	local blinkTimer = MOAITimer.new()
	blinkTimer:setSpan(math.random(self.blinkInterval.min, self.blinkInterval.max))
	blinkTimer:setListener(MOAITimer.EVENT_TIMER_END_SPAN,
		function()
			self:Blink()
		end)
	blinkTimer:start()
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Enemy:Blink()
	local blinkTimer = MOAITimer.new()
	blinkTimer:setSpan(0.05)
	blinkTimer:setMode(MOAITimer.LOOP)
	blinkTimer:setListener(MOAITimer.EVENT_TIMER_LOOP,
		function()
			local nextIndex = self.blinkIndex + 1
			if nextIndex > #self.blinkImages then
				nextIndex = 1
				self.blinkTimer:stop()
				--self:StartNextBlinkTimer()
			end

			self.blinkIndex = nextIndex
			local nextImage = self.blinkImages[self.blinkIndex]
			local imageIndex = self.eyeProp.deck.names[nextImage]
			self.eyeProp:setIndex(imageIndex)
		end)
	blinkTimer:start()
	self.blinkTimer = blinkTimer
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Enemy:Update()
	local player = self.world.player

	local moveSpeed = 20
	local minDistanceFromPlayer = 200
	local maxMoveSpeed = self.enemyInfo.maxMoveSpeed
	
	local position = { self.body:getPosition() }
	local playerPosition = { player.body:getPosition() }
	local directionToPlayer = math.subVec(playerPosition, position)
	local distanceToPlayer = math.length(directionToPlayer)
	directionToPlayer = math.divVecScl(directionToPlayer, distanceToPlayer)	
	
	if maxMoveSpeed > 0 then
		
		-- dtreadgold: Clamp the movement speed to max move speed
		local velocity = { self.body:getLinearVelocity() }
		if math.lengthSqrd(velocity) > maxMoveSpeed * maxMoveSpeed then
			velocity = math.normalise(velocity)
			velocity = math.mulVecScl(velocity, maxMoveSpeed)
			
			self.body:setLinearVelocity(unpack(velocity))
		end

		local impuse = { 0, 0 }		
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
		
	end
	
	for weaponIndex, weapon in ipairs(self.weapons) do
		if weapon.canFire then
			self:Fire()		
		end
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
function Enemy:Fire()
	self:Blink()
	
	for weaponIndex, weapon in ipairs(self.weapons) do
		if weapon.fireType == "Radius" then
			weapon:FireRadius(weapon.numberOfProjectiles, weapon.randomOffset)
		elseif weapon.fireType == "AtPlayer" then
			weapon:FireAtTarget(self.world.player)
		elseif weapon.fireType == "Spiral" then
			weapon:FireSpiral(weapon.fireStep)
		end
		
		weapon.canFire = false
	end
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Enemy:Destroy()
	self.body:destroy()
	self.world.layer:removeProp(self.prop)
	self.world.layer:removeProp(self.eyeProp)
end


return Enemy