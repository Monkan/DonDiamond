local Projectile 		= require("World/Projectile")

local Weapon = Class()

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------
function Weapon:Constructor(world, owner, projectileDamage)
	self.world = world
	self.owner = owner
	
	self.projectileDamage = projectileDamage
end


--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Weapon:FireAtTarget(fireAt)
	local fireFromPosition = { self.owner.body:getPosition() }
	local fireAtPosition = { fireAt.body:getPosition() }
	local fireDirection = math.normalise( math.subVec( fireAtPosition, fireFromPosition ) )
	
	self.world:CreateProjectile(self.owner, fireDirection, self.projectileDamage)	
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Weapon:FireRadius(numberOfProjectiles, randomOffset)
	local angleStep = 360 / numberOfProjectiles
	
	local startAngleOffset = 0
	if randomOffset > 0 then
		startAngleOffset = math.random(0, (360 / randomOffset) - 1) * randomOffset
	end
	local direction = { 1, 0 }
	direction = math.rotateVecAngle(direction, startAngleOffset)

	for projectileIndex = 1, numberOfProjectiles do
		self.world:CreateProjectile(self.owner, direction, self.projectileDamage)		
		direction = math.rotateVecAngle(direction, angleStep)
	end
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Weapon:FireSpiral(angleStep)
	self.prevAngle = self.prevAngle or math.random(0, 360)
	local angle = self.prevAngle + angleStep

	local direction = { 1, 0 }
	direction = math.rotateVecAngle(direction, angle)

	self.world:CreateProjectile(self.owner, direction, self.projectileDamage)		
	
	self.prevAngle = angle
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Weapon:FireForward()
	local direction = { self.owner.body:getLinearVelocity() }
	local length = math.length(direction)
	if length < 0.1 then
		return
	end

	direction = math.divVecScl(direction, length)
	self.world:CreateProjectile(self.owner, direction, self.projectileDamage)
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Weapon:FireBackward()
	local direction = { self.owner.body:getLinearVelocity() }
	local length = math.length(direction)
	if length < 0.1 then
		return
	end

	direction = math.divVecScl(direction, length)
	self.world:CreateProjectile(self.owner, {-direction[1], -direction[2]}, self.projectileDamage)
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Weapon:FireUp()
	local direction = { 0, 1 }
	self.world:CreateProjectile(self.owner, direction, self.projectileDamage)
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Weapon:FireDown()
	local direction = { 0, -1 }
	self.world:CreateProjectile(self.owner, direction, self.projectileDamage)
end


return Weapon