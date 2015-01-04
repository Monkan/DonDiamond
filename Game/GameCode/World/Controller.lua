local Utils = require("Util/Utils")

local Controller = Class()

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------
function Controller:Constructor()
	self.inputs = 
	{
		moveX 	= 0,
		moveY 	= 0,
		fire	= false,
		targetX	= 0,
		targetY = 0
	}
	
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
		self.inputs["targetX"] = x
		self.inputs["targetY"] = y
	end
	MOAIInputMgr.device.pointer:setCallback(onPointerEvent)
end

--------------------------------------------------------------------------------
-- 
--------------------------------------------------------------------------------
function Controller:SetupMobileInputs()
	-- dtreadgold: Get the movement inputs from the accelerometer
	function onLevelEvent( x, y, z )
		self.inputs["moveX"] = x
		self.inputs["moveY"] = y
		print ( "Motion: x=" .. x .. ", y=" .. y .. ", z=" .. z )
	end
	MOAIInputMgr.device.level:setCallback( onLevelEvent )

	-- dtreadgold: Get the fire and target inputs from the touch sensor
	function onTapEvent( eventType, idx, x, y, tapCount  )		
		if eventType == MOAITouchSensor.TOUCH_DOWN then
			self.inputs["fire"] = true
		elseif eventType == MOAITouchSensor.TOUCH_UP then
			self.inputs["fire"] = false			
		end
		
		self.inputs["targetX"] = x
		self.inputs["targetY"] = y
	end
	MOAIInputMgr.device.touch:setCallback( onTapEvent )
end

return Controller