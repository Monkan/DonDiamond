----------------------------------------------------------------------------------------------------
-- 
--
-- @author 
-- @release 
----------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------
 -- Return a random float in range min - max
--------------------------------------------------------------------------------
function math.randomFloat( min, max )
	local returnNo = min + math.random() * (max - min)
	return returnNo
end

--------------------------------------------------------------------------------
 -- Return a random direction (-1 or 1)
--------------------------------------------------------------------------------
function math.randomSign()
	local direction = math.random(0, 1)
	if direction == 0 then
		return -1
	else
		return 1
	end
end

--------------------------------------------------------------------------------
-- *****************************************************************************
-- VECTOR FUNCTIONS
-- *****************************************************************************
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
 -- Convert Cartesian vector table to Polar coords around an optional origin also given as a table
 -- v[1], v[2] - (optional) o[1], o[2]
 -- Returns a Polar vector table 
--------------------------------------------------------------------------------
function math.cartesianToPolar( v, o )
	o = o or { 0, 0 }
	local t = math.atan2( v[2], v[1] )
	local r = math.distance( v[1], v[2], o[1], o[2] )
	return { t, r, v[3] }
end

--------------------------------------------------------------------------------
 -- Convert Polar vector table to Cartesian coords
 -- p[1], p[2] are angle (theta) and distance (radius)
 -- Returns a Cartesian vector table 
--------------------------------------------------------------------------------
function math.polarToCartesian( v )
	if v[2] == 0 then
		return { math.cos(v[1]), 0 }
	end
	local x = v[2] * math.cos(v[1])
	local y = v[2] * math.sin(v[1])
	return { x, y, v[3] }
end

--------------------------------------------------------------------------------
 -- Get the angle between 2 vectors from 2 vector tables 
--------------------------------------------------------------------------------
function math.getRotation( v1, v2 )
	local diffX = v2[1] - v1[1]
	local diffY = v2[2] - v1[2]
	return math.deg( math.atan2( diffY, diffX ) ) - 90
end

--------------------------------------------------------------------------------
 -- Return distanceSqrd between two positions
--------------------------------------------------------------------------------
function math.distanceSqrd( v1, v2 )
    local dX = v2[1] - v1[1]
    local dY = v2[2] - v1[2]
    local distSqrd = ( dX * dX ) + ( dY * dY )
    return distSqrd
end

--------------------------------------------------------------------------------
 -- Return distance between two positions
--------------------------------------------------------------------------------
function math.distance( v1, v2 )
    local dist = math.sqrt( math.distanceSqrd(v1, v2) )
    return dist
end

--------------------------------------------------------------------------------
 -- Return lengthSqrd of a vector
--------------------------------------------------------------------------------
function math.lengthSqrd( v )
    local lengthSqrd = ( v[1] * v[1] ) + ( v[2] * v[2] )
    return lengthSqrd
end

--------------------------------------------------------------------------------
 -- Return lengthSqrd of a vector
--------------------------------------------------------------------------------
function math.length( v )
    local length = math.sqrt( math.lengthSqrd(v) )
    return length
end

--------------------------------------------------------------------------------
 -- Add 2 vector tables 
 -- v1[1] + v2[1], v1[2] + v2[2]
--------------------------------------------------------------------------------
function math.addVec( v1, v2 )
	return { v1[1] + v2[1], v1[2] + v2[2] }
end
--------------------------------------------------------------------------------
 -- Add a vector table with a scalar 
 -- v1[1] + scl, v1[2] + scl
--------------------------------------------------------------------------------
function math.addVecScl( v, scl )
	return { v[1] + scl, v[2] + scl }
end


--------------------------------------------------------------------------------
 -- Multiply 2 vector tables 
 -- v1[1] * v2[1], v1[2] * v2[2] 
--------------------------------------------------------------------------------
function math.mulVec( v1, v2 )
	return { v1[1] * v2[1], v1[2] * v2[2] }
end
--------------------------------------------------------------------------------
 -- Multiply a vector table with a scalar 
 -- v1[1] * scl, v1[2] * scl
--------------------------------------------------------------------------------
function math.mulVecScl( v, scl )
	return { v[1] * scl, v[2] * scl }
end

--------------------------------------------------------------------------------
 -- Divide 2 vector tables 
 -- v1[1] / v2[1], v1[2] / v2[2] 
--------------------------------------------------------------------------------
function math.divVec( v1, v2 )
	return { v1[1] / v2[1], v1[2] / v2[2] }
end
--------------------------------------------------------------------------------
 -- Divide a vector table with a scalar 
 -- v1[1] / scl, v1[2] / scl
--------------------------------------------------------------------------------
function math.divVecScl( v, scl )
	return { v[1] / scl, v[2] / scl }
end

--------------------------------------------------------------------------------
 -- Subtract 2 vector tables 
 -- v1[1] - v2[1], v1[2] - v2[2] 
--------------------------------------------------------------------------------
function math.subVec( v1, v2 )
	return { v1[1] - v2[1], v1[2] - v2[2] }
end
--------------------------------------------------------------------------------
 -- Subtract a vector table with a scalar 
 -- v1[1] - scl, v1[2] - scl
--------------------------------------------------------------------------------
function math.subVecScl( v, scl )
	return { v[1] - scl, v[2] - scl }
end

--------------------------------------------------------------------------------
 -- math.min all elements of a vector table with a value
--------------------------------------------------------------------------------
function math.minVec( v, value )
	return { math.min( v[1], value ), math.min( v[2], value ) }
end

--------------------------------------------------------------------------------
 -- math.max all elements of a vector table with a value
--------------------------------------------------------------------------------
function math.maxVec( v, value )
	return { math.max( v[1], value ), math.max( v[2], value ) }
end

function math.cross(vec1, vec2)
	local returnVec = {}
	returnVec[1] = vec1[2] * vec2[3] - vec1[3] * vec2[2]
	returnVec[2] = vec1[3] * vec2[1] - vec1[1] * vec2[3]
	returnVec[3] = vec1[1] * vec2[2] - vec1[2] * vec2[1]
	return returnVec
end

function math.dotProduct( v1, v2 )
	return (v1[1] * v2[1]) + (v1[2] * v2[2])
end

--------------------------------------------------------------------------------
 -- Normalise a vector table
--------------------------------------------------------------------------------
function math.normalise( v )
    local length = math.length( v )
    return math.divVecScl( v, length )
end

--------------------------------------------------------------------------------
 -- Rotate a vector to face a new direction
--------------------------------------------------------------------------------
function math.rotateVecDir( v, direction )
	local angle = math.atan2( direction[2], direction[1] )
	local cos = math.cos(angle)
	local sin = math.sin(angle)
		
	local rotatedVector = 
	{
		v[1] * cos - v[2] * sin,
		v[1] * sin + v[2] * cos
	}
	
	return rotatedVector
end

--------------------------------------------------------------------------------
 -- Rotate a vector by and angle in degrees
--------------------------------------------------------------------------------
function math.rotateVecAngle( v, angleDeg )
	angleRad = math.rad( angleDeg )
	local cos = math.cos(angleRad)
	local sin = math.sin(angleRad)
		
	local rotatedVector = 
	{
		v[1] * cos - v[2] * sin,
		v[1] * sin + v[2] * cos
	}
	
	return rotatedVector
end
