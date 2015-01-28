local Physics = {}

--------------------------------------------------------------------------------
-- Create a Box2D body from a Physics Body Editor file
--------------------------------------------------------------------------------
function Physics:CreateBodies(physicsWorld, editorFile, bodyType)
	local bodies = {}

	local dataBuffer = MOAIDataBuffer.new()
    dataBuffer:load( editorFile )
    -- dataBuffer:inflate()
	local json = MOAIJsonParser.decode( dataBuffer:getString() )
	for bodyIndex, bodyInfo in ipairs(json["rigidBodies"]) do
		local body = physicsWorld:addBody ( bodyType )
		body.name = bodyInfo.name
		for shapeIndex, shapeInfo in ipairs(bodyInfo.shapes) do
			if shapeInfo.type == "POLYGON" then
				local vertices = {}
				for pairIndex, vertexPair in ipairs(shapeInfo.vertices) do
					table.insert(vertices, vertexPair.x)
					table.insert(vertices, vertexPair.y)
				end

				local fixture = body:addPolygon(vertices)
			end
		end
		
		table.insert(bodies, body)
	end
	
	return bodies
end

return Physics