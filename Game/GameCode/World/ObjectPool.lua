local ObjectPool = Class()

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------
function ObjectPool:Constructor(world, class, initialQuantity)
	self.pool = {}
	self.freePool = {}
	self.world = world
	
	self.class = class
	
	self:CreateObjects(initialQuantity)
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function ObjectPool:CreateObjects(amount)
	for objectCount = 1, amount do
		local object = self.class(self.world)
		table.insert(self.pool, object)
		self:FreeObject(object)
	end
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function ObjectPool:GetFreeObject()
	if #self.freePool > 0 then
		local object = self.freePool[#self.freePool]
		table.remove(self.freePool, #self.freePool)
		return object
	else
		self:CreateObjects(10)
		return self:GetFreeObject()
	end
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function ObjectPool:FreeObject(object)
	table.insert(self.freePool, object)
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function ObjectPool:Destroy()
	for objectIndex, object in ipairs(self.pool) do
		if object.Destroy then
			object:Destroy()
		end
	end
	
	self.pool = nil
	self.freePool = nil
end

return ObjectPool