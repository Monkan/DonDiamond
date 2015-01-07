local Controller 		= require("World/Controller")
local TexturePacker 	= require("Util/TexturePacker")
local CollisionFilters 	= require("World/CollisionFilters")
local Projectile 		= require("World/Projectile")

local Player = Class()

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------
function Player:Constructor(world)
	self.controller = Controller()
	self.initialHealth = 100
	self.health = self.initialHealth
	self.points = 0
	self.faction = "Good"
	self.world = world
	
	self:Initialise(world)
	
	self.canFire = true
	local fireRate = 0.5
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
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Player:Initialise(world)
	local layer = world.layer
	local physicsWorld = world.physicsWorld

	-- dtreadgold: Set up player
	local playerQuad = MOAIGfxQuad2D.new ()
	playerQuad:setTexture ( GRAPHICS_DIR .. "playerbody.png" )
	local size = { 100, 67 }
	playerQuad:setRect ( -size[1] / 2, -size[2] / 2, size[1] / 2, size[2] / 2 )

	self.prop = MOAIProp2D.new()
	self.prop:setDeck ( playerQuad )
	layer:insertProp ( self.prop )
	
	local worldBody = physicsWorld:addBody ( MOAIBox2DBody.DYNAMIC )
	local fixture = worldBody:addCircle( 0, 0, size[1] / 2 )
	--local fixture = worldBody:addRect( -size[1] / 2, -size[2] / 2, size[1] / 2, size[2] / 2 )
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
					if self.health < 0 then
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
	local mouthDeck, names = TexturePacker:Load(GRAPHICS_DIR .. "playerMouths.lua", GRAPHICS_DIR .. "playerMouths.png")
	mouthDeck.names = names

	self.mouthProp = MOAIProp2D.new()
	self.mouthProp:setDeck ( mouthDeck )
	self.mouthProp.deck = mouthDeck
	layer:insertProp ( self.mouthProp )
	self.mouthProp:setLoc(0, 0)	
	self.mouthProp:setAttrLink(MOAITransform.INHERIT_TRANSFORM, self.prop, MOAITransform.TRANSFORM_TRAIT)
	
	self:SetMood("Happy")
	
	-- dtreadgold: Add the prop for the crown
	local crownQuad = MOAIGfxQuad2D.new ()
	crownQuad:setTexture ( GRAPHICS_DIR .. "crown.png" )
	local crownSize = { 35, 32 }
	crownQuad:setRect ( -crownSize[1] / 2, -crownSize[2] / 2, crownSize[1] / 2, crownSize[2] / 2 )

	self.crownProp = MOAIProp2D.new()
	self.crownProp:setDeck ( crownQuad )
	self.crownProp.deck = crownQuad
	layer:insertProp ( self.crownProp )
	self.crownProp:setLoc(0, 50)
	
	self.crownProp:setAttrLink(MOAITransform.INHERIT_TRANSFORM, self.prop, MOAITransform.TRANSFORM_TRAIT)

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

	--local playerLoc = { self.player:getLoc() }
	--self.player:setLoc(playerLoc[1] + 1, playerLoc[2])
	
	local moveSpeed = 20
	local maxMoveSpeed = 200
	
	-- dtreadgold: Clamp the movement speed to max move speed
	local velocity = { self.body:getLinearVelocity() }
	if math.lengthSqrd(velocity) > maxMoveSpeed * maxMoveSpeed then
		velocity = math.normalise(velocity)
		velocity = math.mulVecScl(velocity, maxMoveSpeed)
		
		self.body:setLinearVelocity(unpack(velocity))
	end
	
	local impuse = { 0, 0 }
	impuse[1] = moveSpeed * self.controller.inputs["moveX"]
	impuse[2] = moveSpeed * self.controller.inputs["moveY"]
	
	self.body:applyLinearImpulse(impuse[1], impuse[2])
	
	--[[
	if math.lengthSqrd(velocity) > 0 then
		local position = { self.body:getPosition() }
		self.body:setTransform( position[1], position[2], math.deg(math.atan2(velocity[2], velocity[1])) + 90 )
	end
	--]]
	
	-- dtreadgold: Check if we should fire
	if self.controller.inputs['fire'] and self.canFire then
		local mouseX = self.controller.inputs["targetX"]
		local mouseY = self.controller.inputs["targetY"]
		local mousePosition = { self.world.layer:wndToWorld( mouseX, mouseY ) }
		local fireDirection = math.subVec( mousePosition, { self.body:getPosition() } )
		fireDirection = math.normalise(fireDirection)
		self:Fire(fireDirection)
	end
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Player:Fire(fireDirection)	
	local projectile = Projectile(self.world, self, fireDirection)
	table.insert(self.world.projectiles, projectile)
	self.canFire = false
	
	-- dtreadgold: Stop and start the timer again to make sure we can't fire too soon
	self.fireTimer:stop()
	self.fireTimer:start()
end



return Player