local EnemyBlue = 
{
	weapons =
	{
		{
			fireType 			= "Radius",
			fireRate			= 1,
			numberOfProjectiles = 2,
			randomOffset		= 45,
			projectileDamage	= 3,
		}
	},
	
	health 				= 30,
	maxMoveSpeed		= 150,
	points				= 3,
	
	textures = 
	{
		"blue_25.png",
		"blue_50.png",
		"blue_75.png",
		"blue_100.png",
	},

	scale				= 0.5,
}

return EnemyBlue