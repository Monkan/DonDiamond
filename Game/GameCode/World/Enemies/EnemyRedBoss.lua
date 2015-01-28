local EnemyRed = 
{
	weapons =
	{
		{
			fireType 			= "Spiral",
			fireRate			= 0.3,
			offsetStep			= 20,
			projectileDamage	= 8,
			direction			= -1
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
			projectileDamage	= 1,
		}
	},
	
	health 				= 150,
	maxMoveSpeed		= 40,
	points				= 17,
	
	textures = 
	{
		"red_25.png",
		"red_50.png",
		"red_75.png",
		"red_100.png",
	},

	scale				= 2.0,
}


return EnemyRed