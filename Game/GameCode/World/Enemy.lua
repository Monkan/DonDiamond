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
	self.world = world
	self.faction = "Bad"
	
	local deck, names = TexturePacker:Load(GRAPHICS_DIR .. "enemies.lua", GRAPHICS_DIR .. "enemies.png")
	deck.names = names
	self.prop = MOAIProp2D.new()
	self.prop:setDeck ( deck )
	self.prop.deck = deck
	
	-- Add the prop for the eye
	self.blinkInterval = { min = 2, max = 5 }
	self.eyeProp = MOAIProp2D.new()
	self.eyeProp:setDeck ( deck )
	self.eyeProp.deck = deck
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
function Enemy:CreatePhysics(physicsWorld)
	local bodyType = MOAIBox2DBody.DYNAMIC
	local worldBody = physicsWorld:addBody ( bodyType )
	--local fixture = worldBody:addCircle( 0, 0, size[1] / 2 )
	local fixture = worldBody:addRect( -self.size[1] / 2, -self.size[2] / 2, self.size[1] / 2, self.size[2] / 2 )
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
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Enemy:Activate(position, enemyInfo)
	self.state = "Attacking"
	table.copy(enemyInfo, self)
	self.maxHealth = self.health
	self.dead = false

	local layer = self.world.layer
	local physicsWorld = self.world.physicsWorld
	
	-- Set up prop and physics
	self.size = { 80, 60 }
	self.size[1] = self.size[1] * self.scale
	self.size[2] = self.size[2] * self.scale
	self.prop:setIndex( self.prop.deck.names[self.textures[4]] )
	
	self.blinkIndex = 1
	self.eyeProp:setIndex( self.prop.deck.names[self.blinkImages[self.blinkIndex]] )
	
	self.prop:setScl(self.scale)
	layer:insertProp( self.prop )
	layer:insertProp( self.eyeProp )
	
	self:CreatePhysics(physicsWorld)
	
	if enemyInfo.weapons then
		self.weapons = {}
		for weaponIndex, weaponData in ipairs(enemyInfo.weapons) do
			local weapon = Weapon(self.world, self, weaponData.projectileDamage)
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
	
	self.body:setTransform(position[1], position[2], 0)
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Enemy:Deactivate()
	local world = self.world
	local layer = world.layer
	
	for weaponIndex, weapon in ipairs(self.weapons) do
		weapon.fireTimer:stop()
	end
	
	if self.blinkTimer then
		self.blinkTimer:stop()
	end

	self.body:destroy()
	self.body = nil
	layer:removeProp(self.prop)
	layer:removeProp(self.eyeProp)
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Enemy:ReduceHealth(amount)
	self.health = self.health - amount
	if self.health <= 0 then
		self.dead = true
	end
	
	-- Set the correct image for the damage amount
	local healthProportion = self.health / self.maxHealth
	if healthProportion < 0.25 then
		self.prop:setIndex( self.prop.deck.names[self.textures[1]] )
	elseif healthProportion < 0.5 then
		self.prop:setIndex( self.prop.deck.names[self.textures[2]] )
	elseif healthProportion < 0.75 then
		self.prop:setIndex( self.prop.deck.names[self.textures[3]] )
	else
		self.prop:setIndex( self.prop.deck.names[self.textures[4]] )
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
	local maxMoveSpeed = self.maxMoveSpeed
	local minSeparationDistance = 100
	
	local position = { self.body:getPosition() }
	local playerPosition = { player.body:getPosition() }
	local directionToPlayer = math.subVec(playerPosition, position)
	local distanceToPlayer = math.length(directionToPlayer)
	directionToPlayer = math.divVecScl(directionToPlayer, distanceToPlayer)	
	
	if maxMoveSpeed > 0 then
		
		-- Clamp the movement speed to max move speed
		local velocity = { self.body:getLinearVelocity() }
		if math.lengthSqrd(velocity) > maxMoveSpeed * maxMoveSpeed then
			velocity = math.normalise(velocity)
			velocity = math.mulVecScl(velocity, maxMoveSpeed)
			
			self.body:setLinearVelocity(unpack(velocity))
		end

		-- Apply movement impuse
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
		
		-- Apply separation to make sure the enemies don't bunch up too much
		local separationImpuse = { 0, 0 }		
		for enemyIndex, enemy in ipairs(self.world.enemies) do
			if enemy ~= self then
				local enemyPosition = { enemy.body:getPosition() }
				local directionToEnemy = math.subVec(enemyPosition, position)
				local distanceToEnemySqrd = math.lengthSqrd(directionToEnemy)

				if distanceToEnemySqrd < minSeparationDistance * minSeparationDistance then
					directionToEnemy = math.normalise(directionToEnemy)	
					separationImpuse = math.addVec(separationImpuse, math.mulVecScl(directionToEnemy, -moveSpeed / 2))
				end
			end
		end
		
		self.body:applyLinearImpulse(separationImpuse[1], separationImpuse[2])
		
	end
	
	for weaponIndex, weapon in ipairs(self.weapons) do
		if weapon.canFire then
			self:Fire()		
		end
	end
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
	self:Deactivate()
end


return Enemy