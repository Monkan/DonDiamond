local Pickup = 
{
	textures = 
	{
		"health.png",
	},

	scale				= 2.0,
	points				= 0,
	frequency			= 2,
	
	OnCollected = function(world)
		world.player:AddHealth(50)
	end,
}

return Pickup