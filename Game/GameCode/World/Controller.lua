local Utils = require("Util/Utils")
local CollisionFilters 	= require("World/CollisionFilters")

local Controller = Class()

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------
function Controller:Constructor(owner)
	self.owner = owner
	self.inputs = 
	{
		moveX 	= 0,
		moveY 	= 0,
		fire	= false,
		targetX	= 0,
		targetY = 0,
		moveToX	= nil,
		moveToY	= nil
	}
	
	self.prevMoveX = 0
	self.prevMoveY = 0
	
	if Utils:IsMobile() then
		self:SetupMobileInputs()
	else
		self:SetupPCInputs()
	end
end

--------------------------------------------------------------------------------
-- 
--------------------------------------------------------------------------------
function Controller:SetupPCInputs()
	-- dtreadgold: Use the keyboard for movement controls
	function onKeyboardEvent( key, down )
		local keyChar = string.char(key)
		
		if keyChar == "w" or keyChar == "W" then
			if down then
				self.inputs["moveY"] = 1
			elseif self.inputs["moveY"] == 1 then
				self.inputs["moveY"] = 0
			end
		elseif keyChar == "s" or keyChar == "S" then
			if down then
				self.inputs["moveY"] = -1
			elseif self.inputs["moveY"] == -1 then
				self.inputs["moveY"] = 0
			end
		end
		
		if keyChar == "d" or keyChar == "D" then
			if down then
				self.inputs["moveX"] = 1
			elseif self.inputs["moveX"] == 1 then
				self.inputs["moveX"] = 0
			end
		elseif keyChar == "a" or keyChar == "A" then
			if down then
				self.inputs["moveX"] = -1
			elseif self.inputs["moveX"] == -1 then
				self.inputs["moveX"] = 0
			end
		end

	end
	MOAIInputMgr.device.keyboard:setCallback( onKeyboardEvent )
	
	function onMouseLeftEvent( down )
		self.inputs["fire"] = down
	end
	MOAIInputMgr.device.mouseLeft:setCallback( onMouseLeftEvent )
	
	function onPointerEvent(x, y)
		local layer = self.owner.world.layer
		local targetPosition = { layer:wndToWorld(x, y) }
		self.inputs["targetX"] = targetPosition[1]
		self.inputs["targetY"] = targetPosition[2]
	end
	MOAIInputMgr.device.pointer:setCallback(onPointerEvent)
end

--------------------------------------------------------------------------------
-- 
--------------------------------------------------------------------------------
function Controller:SetupMobileInputs()
	-- dtreadgold: Get the fire and target inputs from the touch sensor
	function onTapEvent( eventType, idx, x, y, tapCount  )
		local layer = self.owner.world.layer
		local worldPosition = { layer:wndToWorld(x, y) }

		if eventType == MOAITouchSensor.TOUCH_DOWN then
			self.inputs["fire"] = true
		elseif eventType == MOAITouchSensor.TOUCH_UP then
			self.inputs["fire"] = false
		end
		
		self.inputs["targetX"] = worldPosition[1]
		self.inputs["targetY"] = worldPosition[2]
		
		self.inputs["moveToX"] = worldPosition[1]
		self.inputs["moveToY"] = worldPosition[2]
	end
	MOAIInputMgr.device.touch:setCallback( onTapEvent )
end


--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Controller:Reset()
	self.inputs = 
	{
		moveX 	= 0,
		moveY 	= 0,
		fire	= false,
		targetX	= 0,
		targetY = 0,
		moveToX	= nil,
		moveToY	= nil
	}
end

return Controller