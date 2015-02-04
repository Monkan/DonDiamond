local Controller 		= require("World/Controller")
local TexturePacker 	= require("Util/TexturePacker")
local CollisionFilters 	= require("World/CollisionFilters")
local Projectile 		= require("World/Projectile")
local Particles 		= require("World/Particles")
local Weapon			= require("World/Weapon")

local Player = Class()

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------
function Player:Constructor(world)
	self.world = world

	self.initialHealth = 50
	self.health = self.initialHealth
	self.faction = "Good"
	self.projectileDamage = 2

	self.pointsPerLevel = 30
	self.points = 0
	
	self.maxMoveSpeed = 250
	self.maxLevel = 30
	
	self.controller = Controller(self)
	self:Initialise(world)
	
	self.canFire = true
	local fireRate = 0.2
	local fireTimer = MOAITimer.new()
	fireTimer:setSpan(fireRate)
	fireTimer:setMode(MOAITimer.LOOP)
	fireTimer:setListener(MOAITimer.EVENT_TIMER_LOOP,
		function()
			self.canFire = true
		end)
	fireTimer:start()
	
	self.fireTimer = fireTimer
	
	-- dtreadgold: Jiggle the prop
	local rotateAmount = 5
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
		self.crownProp:moveRot( -rotation, 0.5 )
		action:setListener( MOAIAction.EVENT_STOP, self.onSpinStop )
	end

	self.spin(self.spinDirection * rotateAmount)
	
	--self.particles = Particles(world, CONTENT_DIR .. "Particles/particle.pex")
	--self.particles.system:setAttrLink(MOAITransform.INHERIT_TRANSFORM, self.prop, MOAITransform.TRANSFORM_TRAIT)
	
	self.weapon = Weapon(world, self, self.projectileDamage)
	self.weapon2 = Weapon(world, self, self.projectileDamage)
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Player:Initialise(world)
	local layer = world.layer
	local physicsWorld = world.physicsWorld

	-- dtreadgold: Set up player
	local deck, names = TexturePacker:Load(GRAPHICS_DIR .. "player.lua", GRAPHICS_DIR .. "player.png")
	deck.names = names

	self.prop = MOAIProp2D.new()
	self.prop:setDeck ( deck )
	self.prop:setIndex( deck.names["playerbody.png"] )
	self.prop.deck = deck
	layer:insertProp ( self.prop )
	local size = { 100, 67 }
	
	local worldBody = physicsWorld:addBody ( MOAIBox2DBody.DYNAMIC )
	--local fixture = worldBody:addCircle( 0, 0, size[1] / 2 )
	local fixture = worldBody:addRect( -size[1] / 2, -size[2] / 2, size[1] / 2, size[2] / 2 )
	fixture:setFilter( CollisionFilters.Category.Player, CollisionFilters.Mask.Player )
	
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
					
					self:SetMood("Sad")
				end
			end
		end
	end
	fixture:setCollisionHandler( onCollide, MOAIBox2DArbiter.BEGIN + MOAIBox2DArbiter.END )
	
	self.prop:setAttrLink(MOAITransform.INHERIT_TRANSFORM, worldBody, MOAITransform.TRANSFORM_TRAIT)
	worldBody.owner = self

	self.body = worldBody
	self.body:setLinearDamping(3)
	
	-- dtreadgold: Add the prop for the mouth
	self.mouthProp = MOAIProp2D.new()
	self.mouthProp:setDeck ( deck )
	self.mouthProp.deck = deck
	layer:insertProp ( self.mouthProp )
	self.mouthProp:setLoc(0, 0)	
	self.mouthProp:setAttrLink(MOAITransform.INHERIT_TRANSFORM, self.prop, MOAITransform.TRANSFORM_TRAIT)
	
	self:SetMood("Happy")
	
	-- dtreadgold: Add the prop for the crown
	self.crownProp = MOAIProp2D.new()
	self.crownProp:setDeck ( deck )
	self.crownProp:setIndex( deck.names["crown.png"] )
	self.crownProp.deck = deck
	layer:insertProp ( self.crownProp )
	self.crownProp:setLoc(0, 50)
	self:AddPoints(0)
	
	self.crownProp:setAttrLink(MOAITransform.INHERIT_TRANSFORM, self.prop, MOAITransform.TRANSFORM_TRAIT)

end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Player:AddPoints(amount)
	local oldLevel = math.floor(self.points / self.pointsPerLevel)
	self.points = self.points + amount
	
	local newLevel = math.floor(self.points / self.pointsPerLevel)
	if newLevel > oldLevel then
		self:LevelUp(newLevel)
	end

	-- dtreadgold: Get the amount of points for this level to use as a scale for the crown
	self.levelPoints = (self.points / self.pointsPerLevel) - newLevel
	local minCrownScale = 0.3
	local maxCrownScale = 0.8
	-- dtreadgold: Get the scale in the range min and max scale
	local crownScale = (self.levelPoints * (maxCrownScale - minCrownScale)) + minCrownScale
	self.crownProp:seekScl(crownScale, crownScale, 1.0)
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Player:LevelUp(newLevel)
	if newLevel > self.maxLevel then
		-- dtreadgold: Only level up as far as max level
		return
	end

	local levelScale = 1 + ((newLevel + 1) / self.maxLevel)
	self.prop:seekScl(levelScale, levelScale, 1.0)
	
	self.health = math.min( self.health + (newLevel * 10), self.initialHealth )
	if newLevel % 2 == 0 then
		self.projectileDamage = self.projectileDamage + 2
	else
		self.maxMoveSpeed = self.maxMoveSpeed + 50
	end
	
	-- dtreadgold: Spin the crown on level up
	local spinDirection = math.randomSign()
	self.crownProp:moveRot(spinDirection * 360, 0.5)
end


--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Player:SetMood(mood)
	if mood == "Sad" then
		if self.moodTimer then
			self.moodTimer:stop()
			self.moodTimer = nil
		end

		local sadImages = 
		{
			--"sad1.png",
			"sad2.png"
		}
		local mouthImage = sadImages[math.random(1, #sadImages)]
		self.mouthProp:setIndex(self.mouthProp.deck.names[mouthImage])
		
		-- dtreadgold: Mouth changing timer
		self.moodTimer = MOAITimer.new()
		self.moodTimer:setSpan(0.5)
		self.moodTimer:setListener(MOAITimer.EVENT_TIMER_END_SPAN,
			function()
				self:SetMood("Happy")
			end)
		self.moodTimer:start()
	elseif mood == "Happy" then
		local sadImages = 
		{
			"smile2.png",
			"smile3.png"
		}
		local mouthImage = sadImages[math.random(1, #sadImages)]
		self.mouthProp:setIndex(self.mouthProp.deck.names[mouthImage])
	end
end


--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Player:Update()

	self.controller:Update()

	local moveSpeed = 50
	local maxMoveSpeed = self.maxMoveSpeed
	
	-- dtreadgold: Clamp the movement speed to max move speed
	local velocity = { self.body:getLinearVelocity() }
	if math.lengthSqrd(velocity) > maxMoveSpeed * maxMoveSpeed then
		velocity = math.normalise(velocity)
		velocity = math.mulVecScl(velocity, maxMoveSpeed)
		
		self.body:setLinearVelocity(unpack(velocity))
	end
	
	local impuse = { 0, 0 }
	if self.controller.inputs.moveToX and self.controller.inputs.moveToY then
		-- dtreadgold: Move in the direction of the moveTo
		local moveTo = { self.controller.inputs.moveToX, self.controller.inputs.moveToY }
		local position = { self.body:getPosition() }
		local moveVector = math.subVec( moveTo, position )
		local distance = math.length(moveVector)
		moveVector = math.divVecScl(moveVector, distance)
		
		impuse[1] = moveSpeed * moveVector[1]
		impuse[2] = moveSpeed * moveVector[2]
		
		local minDistance = 10
		if distance < minDistance then
			self.controller.inputs.moveToX = nil
			self.controller.inputs.moveToY = nil
		end
	end
	
	self.body:applyLinearImpulse(impuse[1], impuse[2])
	
	--[[
	-- dtreadgold: Check if we should fire
	if self.canFire then
		self:Fire()
	end
	--]]
	
	--[[
	if math.lengthSqrd(velocity) > 0 then
		local position = { self.body:getPosition() }
		self.body:setTransform( position[1], position[2], math.deg(math.atan2(velocity[2], velocity[1])) + 90 )
	end
	--]]
	
	---[[
	self:FindTarget()

	-- dtreadgold: Check if we should fire
	if self.target and self.canFire then
		self:Fire()
	end
	--]]
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Player:FindTarget()	
	self.target = nil

	-- dtreadgold: Find the closest enemy to fire at
	local position = { self.body:getPosition() }
	local closestEnemy = nil
	local closestDistanceSqrd = nil
	local enemies = self.world.enemies
	for enemyIndex, enemy in ipairs(enemies) do
		local enemyPosition = { enemy.body:getPosition() }
		local distanceSqrd = math.distanceSqrd( enemyPosition, position )
		if not closestDistanceSqrd or distanceSqrd < closestDistanceSqrd then
			closestDistanceSqrd = distanceSqrd
			closestEnemy = enemy
		end
	end
	
	if closestEnemy then
		self.target = closestEnemy
	end
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Player:Fire()
	self.weapon:FireAtTarget(self.target)
	--self.weapon:FireSpiral(20)
	--self.weapon2:FireSpiral(-20)
	--self.weapon:FireForward()
	--self.weapon:FireBackward()
	
	--self.weapon:FireUp()
	--self.weapon:FireDown()

	
	self.canFire = false
	
	-- dtreadgold: Stop and start the timer again to make sure we can't fire too soon
	self.fireTimer:stop()
	self.fireTimer:start()
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Player:Reset()
	self.dead = false
	self.health = self.initialHealth
	self.body:setTransform(0, 0, 0)
	self.body:setLinearVelocity(0, 0)
	self.target = nil
	self.points = 0

	self.controller:Reset()
end



return Player