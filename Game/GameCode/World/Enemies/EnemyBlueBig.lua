local EnemyBlue = 
{
	weapons =
	{
		{
			fireType 			= "Radius",
			fireRate			= 2,
			numberOfProjectiles = 3,
			randomOffset		= 45,
			projectileDamage	= 5,
		}
	},
	
	health 				= 50,
	maxMoveSpeed		= 100,
	points				= 9,
	
	textures = 
	{
		"blue_25.png",
		"blue_50.png",
		"blue_75.png",
		"blue_100.png",
	},

	scale				= 1.0,
}

return EnemyBlue