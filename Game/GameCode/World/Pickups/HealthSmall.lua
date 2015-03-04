local Pickup = 
{
	textures = 
	{
		"health.png",
	},

	scale				= 1.0,
	points				= 0,
	frequency			= 5,
	
	OnCollected = function(world)
		world.player:AddHealth(20)
	end,
}

return Pickup