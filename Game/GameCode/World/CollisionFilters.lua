local CollisionFilters = {}

local Category = 
{
	Player 					= 1,
	FriendlyProjectiles 	= 2,
	Enemy 					= 4,
	EnemyProjectiles 		= 8,
	Environment 			= 16,
	ClickDetectArea 		= 32,
}

local Mask = 
{
	Player 					= Category.Enemy + Category.EnemyProjectiles + Category.Environment,
	FriendlyProjectiles 	= Category.Enemy + Category.EnemyProjectiles + Category.Environment,
	Enemy 					= Category.Player + Category.Enemy + Category.FriendlyProjectiles + Category.EnemyProjectiles + Category.Environment + Category.ClickDetectArea,	
	EnemyProjectiles 		= Category.Player + Category.Enemy + Category.FriendlyProjectiles + Category.Environment,
	Environment				= Category.Player + Category.Enemy + Category.FriendlyProjectiles + Category.EnemyProjectiles + Category.Environment,
	ClickDetectArea			= Category.Enemy,
}

CollisionFilters.Category = Category
CollisionFilters.Mask = Mask

return CollisionFilters