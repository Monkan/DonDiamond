local Utils = {}

--------------------------------------------------------------------------------
-- Returns whether the mobile execution environment.
-- @return True in the case of mobile.
--------------------------------------------------------------------------------
function Utils:IsMobile()
    local brand = MOAIEnvironment.osBrand
    return brand == 'Android' or brand == 'iOS'
end

--------------------------------------------------------------------------------
-- Returns whether the desktop execution environment.
-- @return True in the case of desktop.
--------------------------------------------------------------------------------
function Utils:IsDesktop()
    return not self:isMobile()
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Utils:Timer(span, eventType, callback)
	local timer = MOAITimer.new()
	timer:setSpan(span)
	timer:setListener(eventType, callback)

	return timer
end


return Utils