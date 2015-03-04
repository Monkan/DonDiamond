local Pickup = 
{
	textures = 
	{
		"key.png",
	},

	scale				= 1.0,
	points				= 10,
	frequency			= 0,
	
	OnCollected = function(world)
		world.roomFinished = true
	end,
}

return Pickup