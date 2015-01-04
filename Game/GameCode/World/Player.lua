local Controller 		= require("World/Controller")
local TexturePacker 	= require("Util/TexturePacker")
local CollisionFilters 	= require("World/CollisionFilters")

local Player = Class()

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------
function Player:Constructor(world)
	self.controller = Controller()
	self.health = 100
	self.points = 0
	
	self:Initialise(world)
	
	--[[
	local rotateAmount = 20
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
		local action = self.prop:moveRot( rotation, 0.1 )
		action:setListener( MOAIAction.EVENT_STOP, self.onSpinStop )
	end

	self.spin(self.spinDirection * rotateAmount)
	--]]
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
	local mouthDeck = TexturePacker:Load(GRAPHICS_DIR .. "playerMouths.lua", GRAPHICS_DIR .. "playerMouths.png")

	self.mouthProp = MOAIProp2D.new()
	self.mouthProp:setDeck ( mouthDeck )
	self.mouthProp.deck = mouthDeck
	layer:insertProp ( self.mouthProp )
	self.mouthProp:setLoc(0, 0)
	
	self.mouthProp:setAttrLink(MOAITransform.INHERIT_TRANSFORM, self.prop, MOAITransform.TRANSFORM_TRAIT)
	
	-- dtreadgold: Mouth changing timer
	local timer = MOAITimer.new()
	timer:setSpan(2)
	timer:setMode(MOAITimer.LOOP)
	timer:setListener(MOAITimer.EVENT_TIMER_LOOP,
		function()
			self.mouthProp:setIndex(math.random(1, 6))
		end)
	timer:start()
	
	-- dtreadgold: Add the prop for the crown
	local crownQuad = MOAIGfxQuad2D.new ()
	crownQuad:setTexture ( GRAPHICS_DIR .. "crown.png" )
	local crownSize = { 70, 64 }
	crownQuad:setRect ( -crownSize[1] / 2, -crownSize[2] / 2, crownSize[1] / 2, crownSize[2] / 2 )

	self.crownProp = MOAIProp2D.new()
	self.crownProp:setDeck ( crownQuad )
	self.crownProp.deck = crownQuad
	layer:insertProp ( self.crownProp )
	self.crownProp:setLoc(0, 60)
	
	self.crownProp:setAttrLink(MOAITransform.INHERIT_TRANSFORM, self.prop, MOAITransform.TRANSFORM_TRAIT)

end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Player:Update()

	self.controller:Update()
	
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
	local keyboard = MOAIInputMgr.device.keyboard
	if self.controller.inputs['a'] then
		impuse[1] = -moveSpeed
	elseif self.controller.inputs['d'] then
		impuse[1] = moveSpeed
	end
	
	if self.controller.inputs['s'] then
		impuse[2] = -moveSpeed
	elseif self.controller.inputs['w'] then
		impuse[2] = moveSpeed
	end
	
	self.body:applyLinearImpulse(impuse[1], impuse[2])
	
	--[[
	if math.lengthSqrd(velocity) > 0 then
		local position = { self.body:getPosition() }
		self.body:setTransform( position[1], position[2], math.deg(math.atan2(velocity[2], velocity[1])) + 90 )
	end
	--]]
end


return Player