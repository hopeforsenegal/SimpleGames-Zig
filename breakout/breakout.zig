const raylib = @import("raylib");
const std = @import("std");
const math = std.math;
const print = @import("std").debug.print;
const RndGen = std.rand.DefaultPrng;

const BoardWidthInBricks 	= 12;
const BoardHeightInBricks 	= 13;
const BrickWidthInPixels  	= 64;
const BrickHeightInPixels 	= 24;

const BrickOffsetX 	= 16;
const BrickOffsetY 	= 16;
 
const NumBrickTypes = 4;

const TextAlignment = enum {
	Left, 
	Center,
	Right,
};

const CollisionFace = enum {
	None,
	Left,
	Top,
	Right,
	Bottom,
};

const Brick = struct {
	typeOf:  i32,
	isAlive: bool,
};

const Ball = struct {
	centerPosition: raylib.Vector2,
	size:           raylib.Vector2,
	velocity:  		raylib.Vector2,
};

const InputScheme = struct {
	leftButton:   	raylib.KeyboardKey,
	rightButton: 	raylib.KeyboardKey,
};

const Pad = struct {
	centerPosition: raylib.Vector2,
	size:       	raylib.Vector2,
	velocity:  		raylib.Vector2,
	input: 			InputScheme,
	score:    		i32,
};

var player1:Pad	= undefined;
var ball:Ball	= undefined;
var bricks:[BoardWidthInBricks][BoardHeightInBricks]Brick = undefined;

var InitialBallPosition: raylib.Vector2 = .{.x=0, .y=0};
var InitialBallVelocity: raylib.Vector2 = .{.x=0, .y=0};

pub fn main() void {
    raylib.InitWindow(800, 450, "ZIG Breakout");
	defer raylib.CloseWindow();
    raylib.SetTargetFPS(60);

	try SetupGame();
	
    while (!raylib.WindowShouldClose()) { 
		var dt = raylib.GetFrameTime();
		try Update(dt);
		try Draw();
    }
}

pub fn SetupGame() !void {
	var height = @intToFloat(f32, raylib.GetScreenHeight());
	var width  = @intToFloat(f32, raylib.GetScreenWidth());
    var rnd = RndGen.init(0);

	{ // Setup bricks
		var i:usize = 0;
		while (i < BoardWidthInBricks) : (i += 1) {
			var j:usize = 0;	
			while (j < BoardHeightInBricks) : (j += 1) {	
				bricks[i][j].typeOf =  @mod(rnd.random().int(i32), 4);
				bricks[i][j].isAlive = true;
			}
		}
	}
	{ // Set up ball
		InitialBallPosition = .{ .x=(width / 2), .y=(height - 20)};
		InitialBallVelocity = .{ .x=50, .y=-25};
		ball.velocity 		= InitialBallVelocity;
		ball.centerPosition = InitialBallPosition;
		ball.size 			= .{ .x=10, .y=10};
	}
	{ // Set up player
		player1.size = .{ .x=50, .y=5};
		player1.velocity = .{.x=100, .y=100};
		player1.centerPosition = .{ .x=(width / 2), .y=(height - 10)};
		player1.input = .{
			.leftButton		= raylib.KeyboardKey.KEY_A,
			.rightButton	= raylib.KeyboardKey.KEY_D,
		};
	}
}

pub fn Update(deltaTime:f32) !void {
	var height = @intToFloat(f32, raylib.GetScreenHeight());
	var width  = @intToFloat(f32, raylib.GetScreenWidth());
	var collisionFace = CollisionFace.None;

	{ // Update Player
		if (raylib.IsKeyDown(player1.input.rightButton)) {
			//Update position
			player1.centerPosition.x += (deltaTime * player1.velocity.x);
			//Clamp on right edge
			if (player1.centerPosition.x+(player1.size.x/2) > (width)) {
				player1.centerPosition.x = (width) - (player1.size.x / 2);
			}
		}
		if (raylib.IsKeyDown(player1.input.leftButton)) {
			//Update position
			player1.centerPosition.x -= (deltaTime * player1.velocity.x);
			//Clamp on left edge
			if (player1.centerPosition.x-(player1.size.x/2) < 0) {
				player1.centerPosition.x = (player1.size.x / 2);
			}
		}
	}
	{ // Update ball
		ball.centerPosition.x += deltaTime * ball.velocity.x;
		ball.centerPosition.y += deltaTime * ball.velocity.y;
	}
	//Collisions
	{ // ball boundary collisions
		var isBallOnBottomScreenEdge = ball.centerPosition.y > (height);
		var isBallOnTopScreenEdge = ball.centerPosition.y < (0);
		var isBallOnLeftRightScreenEdge = ball.centerPosition.x > (width) or ball.centerPosition.x < (0);
		if (isBallOnBottomScreenEdge) {
			ball.centerPosition = InitialBallPosition;
			ball.velocity = InitialBallVelocity;
		}
		if (isBallOnTopScreenEdge) {
			ball.velocity.y *= -1;
		}
		if (isBallOnLeftRightScreenEdge) {
			ball.velocity.x *= -1;
		}
	}
	{ // ball brick collisions
		var i:usize = 0;
  loop: while (i < BoardWidthInBricks) : (i += 1) {
			var j:usize = 0;	
			while (j < BoardHeightInBricks) : (j += 1) {
				var brick = &bricks[i][j];
				if (!brick.isAlive) {
					continue;
				}

				//Coords
				var brickX = @intToFloat(f32, (BrickOffsetX + (i * BrickWidthInPixels)));
				var brickY = @intToFloat(f32, (BrickOffsetY + (j * BrickHeightInPixels)));

				//Ball position
				var ballX = ball.centerPosition.x - (ball.size.x / 2);
				var ballY = ball.centerPosition.y - (ball.size.y / 2);

				//Center Brick
				var brickCenterX = brickX + (BrickWidthInPixels / 2);
				var brickCenterY = brickY + (BrickHeightInPixels / 2);

				var hasCollisionX = ballX+ball.size.x >= brickX and brickX+BrickWidthInPixels >= ballX;
				var hasCollisionY = ballY+ball.size.y >= brickY and brickY+BrickHeightInPixels >= ballY;

				if (hasCollisionX and hasCollisionY) {
					brick.isAlive = false;

					//Determine which face of the brick was hit
					var ymin = math.max(brickY, ballY);
					var ymax = math.min(brickY+BrickHeightInPixels, ballY+ball.size.y);
					var ysize = ymax - ymin;
					var xmin = math.max(brickX, ballX);
					var xmax = math.min(brickX+BrickWidthInPixels, ballX+ball.size.x);
					var xsize = xmax - xmin;
					if (xsize > ysize and ball.centerPosition.y > brickCenterY) {
						collisionFace = CollisionFace.Bottom;
					} else if (xsize > ysize and ball.centerPosition.y <= brickCenterY) {
						collisionFace = CollisionFace.Top;
					} else if (xsize <= ysize and ball.centerPosition.x > brickCenterX) {
						collisionFace = CollisionFace.Right;
					} else if (xsize <= ysize and ball.centerPosition.x <= brickCenterX) {
						collisionFace = CollisionFace.Left;
					} else {
						//Could assert or panic here
					}

					break :loop;
				}
			}
		}
	}
	{ // Update ball after collision
		if (collisionFace != CollisionFace.None) {
			var hasPositiveX = ball.velocity.x > 0;
			var hasPositiveY = ball.velocity.y > 0;
			if ((collisionFace == .Top    and hasPositiveX  and hasPositiveY) or
				(collisionFace == .Top    and !hasPositiveX and hasPositiveY) or
				(collisionFace == .Bottom and hasPositiveX  and !hasPositiveY) or
				(collisionFace == .Bottom and !hasPositiveX and !hasPositiveY)) {
				ball.velocity.y *= -1;
			}
			if ((collisionFace == .Left  and hasPositiveX  and hasPositiveY) or
				(collisionFace == .Left  and hasPositiveX  and !hasPositiveY) or
				(collisionFace == .Right and !hasPositiveX and hasPositiveY) or
				(collisionFace == .Right and !hasPositiveX and !hasPositiveY)) {
				ball.velocity.x *= -1;
			}
		}
	}
	{ // Update ball after pad collision
		if (DetectBallTouchesPad(&ball, &player1)) {
			var previousVelocity = ball.velocity;
			var distanceX = ball.centerPosition.x - player1.centerPosition.x;
			var percentage = distanceX / (player1.size.x / 2);
			ball.velocity.x = InitialBallVelocity.x * percentage;
			ball.velocity.y *= -1;
			var newVelocity = vector2_scale(vector2_normalize(ball.velocity), (vector2_length(previousVelocity) * 1.1));
			ball.velocity = newVelocity;
		}
	}
	{ // Detect all bricks popped
		var hasAtLeastOneBrick = false;
		var i:usize = 0;
 loop2: while (i < BoardWidthInBricks) : (i += 1) {
			var j:usize = 0;	
			while (j < BoardHeightInBricks) : (j += 1) {
				var brick = bricks[i][j];
				if (brick.isAlive) {
					hasAtLeastOneBrick = true;
					break :loop2;
				}
			}
		}
		if (!hasAtLeastOneBrick) {
			try SetupGame();
		}
	}
}

pub fn Draw() !void {
	raylib.BeginDrawing();
	defer raylib.EndDrawing();
	raylib.ClearBackground(raylib.BLACK);

	{ // Draw alive bricks
		var i:usize = 0;
		while (i < BoardWidthInBricks) : (i += 1) {
			var j:usize = 0;	
			while (j < BoardHeightInBricks) : (j += 1) {	
				if (!bricks[i][j].isAlive) {
					continue;
				}

				raylib.DrawRectangle(@intCast(c_int, BrickOffsetX+(i*BrickWidthInPixels)), 
									 @intCast(c_int, BrickOffsetY+(j*BrickHeightInPixels)), 
									 BrickWidthInPixels, 
									 BrickHeightInPixels, 
									 TypeToColor(bricks[i][j].typeOf));
			}
		}
	}
	{ // Draw Players
		raylib.DrawRectangle(@floatToInt(c_int, (player1.centerPosition.x-(player1.size.x/2))), 
							 @floatToInt(c_int, (player1.centerPosition.y-(player1.size.y/2))), 
							 @floatToInt(c_int, (player1.size.x)), 
							 @floatToInt(c_int, (player1.size.y)), 
							 raylib.WHITE);
	}
	{ // Draw Ball
		raylib.DrawRectangle(@floatToInt(c_int, (ball.centerPosition.x-(ball.size.x/2))), 
							 @floatToInt(c_int, (ball.centerPosition.y-(ball.size.y/2))), 
							 @floatToInt(c_int,(ball.size.x)), 
							 @floatToInt(c_int,(ball.size.y)), 
							 raylib.WHITE);
	}
}

fn DetectBallTouchesPad(b:*Ball, pad:*Pad) bool {
	var ballX = b.centerPosition.x - (b.size.x / 2);
	var ballY = b.centerPosition.y - (b.size.y / 2);
	var padX = pad.centerPosition.x - (pad.size.x / 2);
	var padY = pad.centerPosition.y - (pad.size.y / 2);
	if (ballY+(b.size.y/2) >= padY and ballX >= padX and ballX <= padX+pad.size.x) {
		return true;
	}
	return false;
}

pub fn TypeToColor(typeOf:i32) raylib.Color {
	return switch (typeOf) {
		0 	 => raylib.WHITE,
		1 	 => raylib.RED,
		2 	 => raylib.GREEN,
		3 	 => raylib.BLUE,
		else => raylib.BLACK, 
	};
}

pub fn vector2_length(v: raylib.Vector2) f32 { // not sure why we aren't importing lib/raymath
    return math.sqrt((v.x*v.x) + (v.y*v.y));
}

pub fn vector2_scale(v: raylib.Vector2, scale: f32) raylib.Vector2 {
    return .{.x=v.x*scale, .y=v.y*scale};
}

pub fn vector2_normalize(v: raylib.Vector2) raylib.Vector2 {
    return vector2_scale(v, 1/vector2_length(v));
}