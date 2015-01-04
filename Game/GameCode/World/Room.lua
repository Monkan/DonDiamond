local Room = Class()

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------
function Room:Constructor()
	self.neighbours = {}
	self.objects = {}
end


return Room