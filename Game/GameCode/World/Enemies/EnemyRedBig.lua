local EnemyRed = 
{
	weapons =
	{
		{
			fireType 			= "Spiral",
			fireRate			= 0.4,
			offsetStep			= 20,
			projectileDamage	= 8,
		},
		{
			fireType 			= "AtPlayer",
			fireRate			= 0.8,
			projectileDamage	= 1,
		}
	},
	
	health 				= 100,
	maxMoveSpeed		= 40,
	points				= 11,
	
	textures = 
	{
		"red_25.png",
		"red_50.png",
		"red_75.png",
		"red_100.png",
	},

	scale				= 1.0,
}


return EnemyRed