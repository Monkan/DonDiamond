local FileIO = {}

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function FileIO.Load(saveGame, entityOrganiser)
	local dataBuffer = MOAIDataBuffer.new()
    dataBuffer:load( saveGame )
    dataBuffer:inflate()
    local jsonString = dataBuffer:getString()
    entityOrganiser.entities = MOAIJsonParser.decode( jsonString )
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function FileIO.Save(saveGame, entityOrganiser)
	local allEntities = entityOrganiser:GetAllEntities()

	local jsonString = MOAIJsonParser.encode( allEntities )
	assert(jsonString, "FileIO.Save, MOAIJsonParser.encode returned nil")

	local dataBuffer = MOAIDataBuffer.new()
	dataBuffer:setString( jsonString )   
	dataBuffer:save( saveGame .. "d", false )
	dataBuffer:deflate()
	dataBuffer:save( saveGame, false )

end

return FileIO