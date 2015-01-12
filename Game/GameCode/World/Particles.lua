local Particles = Class()


--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------
function Particles:Constructor(world, filePath)
	if self:FromPex(filePath) then
		world.layer:insertProp(self.system)
	end
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Particles:FromPex(filePath)
    local plugin =  MOAIParticlePexPlugin.load(filePath)
	if not plugin then
		return false
	end

    local system = MOAIParticleSystem.new()
    system:reserveParticles(plugin:getMaxParticles(), plugin:getSize())
    system:reserveSprites(plugin:getMaxParticles())
    system:reserveStates(1)
    system:setBlendMode(plugin:getBlendMode())

    local state = MOAIParticleState.new()
    state:setTerm(plugin:getLifespan())
    state:setPlugin(plugin)

    local emitter = MOAIParticleTimedEmitter.new()
    emitter:setLoc(0, 0)
    emitter:setSystem(system)
    emitter:setEmission(plugin:getEmission())
    emitter:setFrequency(plugin:getFrequency())
    emitter:setRect( -1, -1, 1, 1 )
	
	local deck = MOAIGfxQuad2D.new()
	deck:setTexture( plugin:getTextureName() )
	deck:setRect( -0.5, -0.5, 0.5, 0.5 ) -- HACK: Currently for scaling we need to set the deck's rect to 1x1
	system:setDeck( deck )

    local timer = MOAITimer.new()
    timer:setSpan(plugin:getDuration())
    timer:setMode(MOAITimer.NORMAL)
    timer:setListener(MOAIAction.EVENT_STOP, function() self:stop() end)

    self.plugin = plugin
    self.emitter = emitter
    self.state = state
    self.timer = timer
	self.system = system

    system:setState(1, state)

	self:start()
	
	return true
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Particles:start()
	self.system:start()
    self.emitter:start()
    if self.plugin:getDuration() > -1 then
        self.timer:start()
    end
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function Particles:stop()
	self.system:stop()
    self.emitter:stop()
    if self.plugin:getDuration() > -1 then
        self.timer:stop()
    end
end

return Particles