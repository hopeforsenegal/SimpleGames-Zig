const raylib = @import("raylib");
const std = @import("std");
const math = std.math;
const print = @import("std").debug.print;
const RndGen = std.rand.DefaultPrng;

const TextAlignment = enum {
	Left, 
	Center,
	Right,
};

const BulletCooldownSeconds 	= 0.3;
const MaxNumBullets  			= 50;
const MaxNumEnemies 			= 50;

const InputScheme = struct {
	leftButton:   	raylib.KeyboardKey,
	rightButton: 	raylib.KeyboardKey,
	shootButton:	raylib.KeyboardKey,
};

const Pad = struct {
	centerPosition: raylib.Vector2,
	size:       	raylib.Vector2,
	velocity:  		raylib.Vector2,
	input: 			InputScheme,
	score:    		i32,
};

const Bullet = struct {
	centerPosition: raylib.Vector2,
	size:           raylib.Vector2,
	velocity: 		raylib.Vector2,
	color:    		raylib.Color,
	isActive: 		bool,
};

const Enemy = struct {
	centerPosition: raylib.Vector2,
	size:           raylib.Vector2,
	velocity: 		raylib.Vector2,
	color:    		raylib.Color,
	isActive: 		bool,
};

var bullets: [MaxNumBullets]Bullet 	= undefined;
var enemies: [MaxNumEnemies]Enemy 	= undefined;
var player1: Pad					= undefined;

var m_TimerBulletCooldown: f32			= 0;
var m_TimerSpawnEnemy: f32				= 0;
var numEnemiesThisLevel: i32			= 0;
var numEnemiesToSpawn: i32				= 0;
var numEnemiesKilled: i32				= 0;
var numLives:i32						= 3;
var IsGameOver:bool	= false;
var IsWin:bool		= false;

var InitialPlayerPosition: raylib.Vector2 = undefined;

var rnd = RndGen.init(0);

pub fn main() void {
    raylib.InitWindow(800, 450, "ZIG Space Invaders");
	defer raylib.CloseWindow();
    raylib.SetTargetFPS(60);

	var height = @intToFloat(f32, raylib.GetScreenHeight());
	var width  = @intToFloat(f32, raylib.GetScreenWidth());
	InitialPlayerPosition = .{ .x=(width / 2), .y=(height - 10)};

	{ // Set up player
		player1.size = .{ .x=25, .y=25};
		player1.velocity = .{ .x=100, .y=100};
		player1.centerPosition = InitialPlayerPosition;
		player1.input = InputScheme{
			.leftButton		= raylib.KeyboardKey.KEY_A,
			.rightButton	= raylib.KeyboardKey.KEY_D,
			.shootButton	= raylib.KeyboardKey.KEY_SPACE,
		};
	}
	{ // init bullets
		var i:usize = 0;
		while (i < MaxNumBullets) : (i += 1) {
			var bullet = &bullets[i];
			{
				bullet.velocity = .{.x=0, .y=400};
				bullet.size = .{.x=5, .y=5};
			}
		}
	}
	{ // init enemies
		var i:usize = 0;
		while (i < MaxNumEnemies) : (i += 1) {
			var enemy = &enemies[i];
			{
				enemy.velocity = .{.x=0, .y=40};
				enemy.size = .{.x=20, .y=20};
				enemy.centerPosition = .{.x=@intToFloat(f32, @mod(rnd.random().int(i32), @floatToInt(i32, width))), .y=-20};
			}
		}
		numEnemiesToSpawn = 10;
		numEnemiesThisLevel = 10;
	}

    while (!raylib.WindowShouldClose()) { 
		var dt = raylib.GetFrameTime();
		try Update(dt);
		try Draw();
    }
}

pub fn Update(deltaTime:f32) !void {
	var height = @intToFloat(f32, raylib.GetScreenHeight());
	var width  = @intToFloat(f32, raylib.GetScreenWidth());

	if (IsGameOver or IsWin) {
		return;
	}

	{ // Update Player
		if (raylib.IsKeyDown(player1.input.rightButton)) {
			// Update position
			player1.centerPosition.x += (deltaTime * player1.velocity.x);
			// Clamp on right edge
			if (player1.centerPosition.x+(player1.size.x/2) > (width)) {
				player1.centerPosition.x = (width) - (player1.size.x / 2);
			}
		}
		if (raylib.IsKeyDown(player1.input.leftButton)) {
			// Update position
			player1.centerPosition.x -= (deltaTime * player1.velocity.x);
			// Clamp on left edge
			if (player1.centerPosition.x-(player1.size.x/2) < 0) {
				player1.centerPosition.x = (player1.size.x / 2);
			}
		}
		if (HasHitTime(&m_TimerBulletCooldown, deltaTime)) {
			if (raylib.IsKeyDown(player1.input.shootButton)) {
				var i:usize = 0;
				while (i < MaxNumBullets) : (i += 1) {
					var bullet = &bullets[i];
					if (!bullet.isActive) {
						m_TimerBulletCooldown = BulletCooldownSeconds;
						bullet.isActive = true;
						{
							bullet.centerPosition.x = player1.centerPosition.x;
							bullet.centerPosition.y = player1.centerPosition.y + (player1.size.y / 4);
							break;
						}
					}
				}
			}
		}
	}
	{ // Update active bullets
		var i:usize = 0;
		while (i < MaxNumBullets) : (i += 1) {
			var bullet = &bullets[i];
			// Movement
			if (bullet.isActive) {
				bullet.centerPosition.y -= bullet.velocity.y * deltaTime;

				// Went off screen
				if ((bullet.centerPosition.y+(bullet.size.y/2)) <= 0) {
					bullet.isActive = false;
				}
			}
		}
	}
	{ // Update active enemies
		var i:usize = 0;
		while (i < numEnemiesThisLevel) : (i += 1) {
			var enemy = &enemies[i];
			// Movement
			if (enemy.isActive) {
				enemy.centerPosition.y += (enemy.velocity.y * deltaTime);

				// Went off screen
				if (enemy.centerPosition.y-(enemy.size.y/2) >= (height)) {
					enemy.centerPosition = .{.x=@intToFloat(f32, @mod(rnd.random().int(i32), @floatToInt(i32, width))), .y=-20};
				} else {
					var enemyX = enemy.centerPosition.x - (enemy.size.x / 2);
					var enemyY = enemy.centerPosition.y - (enemy.size.y / 2);
					{ // bullet | enemy collision
						var j:usize = 0;
						while (j < MaxNumBullets) : (j += 1) {
							var bullet = &bullets[j];
							var bulletX = bullet.centerPosition.x - (bullet.size.x / 2);
							var bulletY = bullet.centerPosition.y - (bullet.size.y / 2);

							var hasCollisionX = bulletX+bullet.size.x >= enemyX and enemyX+enemy.size.x >= bulletX;
							var hasCollisionY = bulletY+bullet.size.y >= enemyY and enemyY+enemy.size.y >= bulletY;

							if (hasCollisionX and hasCollisionY) {
								bullet.isActive = false;
								enemy.isActive = false;
								{
									numEnemiesKilled += 1;
									IsWin = numEnemiesKilled >= numEnemiesThisLevel;
									break;
								}
							}
						}
					}
					{ // player | enemy collision
						var bulletX = player1.centerPosition.x - (player1.size.x / 2);
						var bulletY = player1.centerPosition.y - (player1.size.y / 2);

						var hasCollisionX = bulletX+player1.size.x >= enemyX and enemyX+enemy.size.x >= bulletX;
						var hasCollisionY = bulletY+player1.size.y >= enemyY and enemyY+enemy.size.y >= bulletY;

						if (hasCollisionX and hasCollisionY) {
							enemy.isActive = false;
							{
								player1.centerPosition = InitialPlayerPosition;
								numLives = numLives - 1;
								IsGameOver = numLives <= 0;
							}
						}
					}
				}
			}
		}
	}
	{ // Spawn enemies
		var canSpawn = HasHitInterval(&m_TimerSpawnEnemy, 2.0, deltaTime);
		var i:usize = 0;
		while (i < MaxNumEnemies) : (i += 1) {
			var enemy = &enemies[i];
			// Spawn
			if (!enemy.isActive) {
				if (canSpawn and numEnemiesToSpawn > 0) {
					numEnemiesToSpawn = numEnemiesToSpawn - 1;
					enemy.isActive = true;
					{
						enemy.centerPosition = .{.x=@rem(@intToFloat(f32, rnd.random().int(i32)), width), .y=-20};
						break;
					}
				}
			}
		}
	}
}

pub fn Draw() !void {
	raylib.BeginDrawing();
	defer raylib.EndDrawing();
	raylib.ClearBackground(raylib.WHITE);

	var height = @intToFloat(f32, raylib.GetScreenHeight());
	var width  = @intToFloat(f32, raylib.GetScreenWidth());

	{ // Draw Players
		raylib.DrawRectangle(@floatToInt(c_int, (player1.centerPosition.x-(player1.size.x/2))), 
							 @floatToInt(c_int, (player1.centerPosition.y-(player1.size.y/2))), 
							 @floatToInt(c_int, (player1.size.x)), 
							 @floatToInt(c_int, (player1.size.y)), 
							 raylib.BLACK);
	}
	{ // Draw the bullets
		var i:usize = 0;
		while (i < MaxNumBullets) : (i += 1) {
			var bullet = &bullets[i];
			if (bullet.isActive) {
				raylib.DrawRectangle(@floatToInt(c_int, (bullet.centerPosition.x-(bullet.size.x/2))),
									 @floatToInt(c_int, (bullet.centerPosition.y-(bullet.size.y/2))),
									 @floatToInt(c_int, (bullet.size.x)),
									 @floatToInt(c_int, (bullet.size.y)),
								     raylib.ORANGE);
			}
		}
	}
	{ // Draw the enemies
		var i:usize = 0;
		while (i < MaxNumEnemies) : (i += 1) {
			var enemy = &enemies[i];
			if (enemy.isActive) {
				raylib.DrawRectangle(@floatToInt(c_int, (enemy.centerPosition.x-(enemy.size.x/2))),
									 @floatToInt(c_int, (enemy.centerPosition.y-(enemy.size.y/2))),
									 @floatToInt(c_int, (enemy.size.x)),
									 @floatToInt(c_int, (enemy.size.y)),
									 raylib.BLUE);
			}
		}
	}
	{ // Draw Info
		DrawText(raylib.TextFormat("Lives %d", numLives), TextAlignment.Left, 15, 5, 20);

		if (IsGameOver) {
			DrawText(raylib.TextFormat("Game Over"), TextAlignment.Center, @floatToInt(c_int, width/2), @floatToInt(c_int, height/2), 50);
		}
		if (IsWin) {
			DrawText(raylib.TextFormat("You Won"), TextAlignment.Center, @floatToInt(c_int, width/2), @floatToInt(c_int, height/2), 50);
		}
	}
}

pub fn DrawText(text:[*c]const u8, alignment:TextAlignment, posX:i32, posY:i32, fontSize :i32) void {
	var fontColor = raylib.DARKGRAY;
	if (alignment == TextAlignment.Left) {
		 raylib.DrawText(text, posX, posY, fontSize, fontColor);
	} else if (alignment == TextAlignment.Center) {
		var scoreSizeLeft = raylib.MeasureText(text, fontSize);
		raylib.DrawText(text, (posX - @divFloor(scoreSizeLeft,2)), posY, fontSize, fontColor);
	} else if (alignment == TextAlignment.Right) {
		var scoreSizeLeft = raylib.MeasureText(text, fontSize);
		raylib.DrawText(text, (posX - scoreSizeLeft), posY, fontSize, fontColor);
	}
}

fn HasHitInterval(timeRemaining:*f32, resetTime:f32, deltaTime:f32) bool {
	timeRemaining.* -= deltaTime;
	if (timeRemaining.* <= 0) {
		timeRemaining.* = resetTime;
		return true;
	}
	return false;
}

fn HasHitTime (timeRemaining:*f32, deltaTime:f32) bool {
	timeRemaining.* = timeRemaining.* - deltaTime;
	return timeRemaining.* <= 0;
}
