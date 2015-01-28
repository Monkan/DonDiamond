local EnemyBlue = 
{
	weapons =
	{
		{
			fireType 			= "Radius",
			fireRate			= 1.5,
			numberOfProjectiles = 5,
			randomOffset		= 45,
			projectileDamage	= 10,
		},
		{
			fireType 			= "AtPlayer",
			fireRate			= 0.8,
			projectileDamage	= 5,
		}
	},
	
	health 				= 100,
	maxMoveSpeed		= 80,
	points				= 15,
	
	textures = 
	{
		"blue_25.png",
		"blue_50.png",
		"blue_75.png",
		"blue_100.png",
	},

	scale				= 2.0,
}

return EnemyBlue