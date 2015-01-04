local Controller = Class()

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------
function Controller:Constructor()
	self.inputs = {}

	function onKeyboardEvent( key, down )
		self.inputs[string.char(key)] = down
	end

	MOAIInputMgr.device.keyboard:setCallback( onKeyboardEvent )
end



--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Controller:Update()
end

return Controller