local Enemy = 
{
	weapons =
	{
		{
			fireType 			= "Radius",
			fireRate			= 2,
			numberOfProjectiles = 3,
			randomOffset		= 45,
			projectileDamage	= 5,
		},
		{
			fireType 			= "Spiral",
			fireRate			= 0.3,
			offsetStep			= 20,
			projectileDamage	= 8,
			direction			= -1,
		},
		{
			fireType 			= "Spiral",
			fireRate			= 0.3,
			offsetStep			= 20,
			projectileDamage	= 8,
			direction			= 1
		},
		{
			fireType 			= "AtPlayer",
			fireRate			= 0.8,
			projectileDamage	= 5,
		}		
	},
	
	health 				= 500,
	maxMoveSpeed		= 20,
	points				= 25,
	
	textures = 
	{
		"blue_25.png",
		"blue_50.png",
		"blue_75.png",
		"blue_100.png",
	},

	scale				= 1.0,
}

return Enemy