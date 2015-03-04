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
		moveToX	= nil,
		moveToY	= nil,
		mouseX	= 0,
		mouseY 	= 0,
		mouseDown = false,
		boost = false,
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
	
	--[[
	-- Use the keyboard for movement controls
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
	--]]
	
	function onMouseLeftEvent( down )
		self.inputs.mouseDown = down
	end
	MOAIInputMgr.device.mouseLeft:setCallback( onMouseLeftEvent )
	
	function onMouseRightEvent( down )
		self.inputs.boost = true
	end
	MOAIInputMgr.device.mouseRight:setCallback( onMouseRightEvent )
	
	function onPointerEvent(x, y)
		self.inputs.mouseX = x
		self.inputs.mouseY = y
	end
	MOAIInputMgr.device.pointer:setCallback(onPointerEvent)
end

--------------------------------------------------------------------------------
-- 
--------------------------------------------------------------------------------
function Controller:SetupMobileInputs()
	-- Get the fire and target inputs from the touch sensor
	function onTapEvent( eventType, idx, x, y, tapCount  )
		local layer = self.owner.world.layer
		local worldPosition = { layer:wndToWorld(x, y) }
		
		if tapCount >= 2 then
			self.inputs.boost = true
		end

		self.inputs.moveToX = worldPosition[1]
		self.inputs.moveToY = worldPosition[2]
	end
	MOAIInputMgr.device.touch:setCallback( onTapEvent )
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Controller:Update()
	if self.inputs.mouseDown then
		local layer = self.owner.world.layer
		local worldPosition = { layer:wndToWorld(self.inputs.mouseX, self.inputs.mouseY) }

		self.inputs.moveToX = worldPosition[1]
		self.inputs.moveToY = worldPosition[2]
	end
end


--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Controller:Reset()
	self.inputs = 
	{
		moveToX	= nil,
		moveToY	= nil,
		mouseX	= 0,
		mouseY 	= 0,
		mouseDown = false
	}
end

return Controller