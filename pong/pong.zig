const raylib = @import("raylib");
const std = @import("std");

const TextAlignment = enum {
	Left, 
	Center,
	Right,
};

const Ball = struct {
	centerPosition: raylib.Vector2,
	size:           raylib.Vector2,
	velocity:  		raylib.Vector2,
};

const InputScheme = struct {
	upButton:   raylib.KeyboardKey,
	downButton: raylib.KeyboardKey,
};

const Pad = struct {
	centerPosition: raylib.Vector2,
	size:       	raylib.Vector2,
	velocity:  		raylib.Vector2,
	input: 			InputScheme,
	score:    		i32,
};

var players:[2]Pad 	= undefined;
var player1 		= &players[0];
var player2 		= &players[1];
var ball    		= Ball {
	.centerPosition = .{.x=0, .y=0},
	.size 			= .{.x=0, .y=0},
	.velocity  		= .{.x=0, .y=0},
};

var InitialBallPosition: raylib.Vector2 = .{.x=0, .y=0};

pub fn main() void {
    raylib.InitWindow(800, 450, "ZIG Pong");
	defer raylib.CloseWindow();
    raylib.SetTargetFPS(60);
	
	var height = @intToFloat(f32, raylib.GetScreenHeight());
	var width  = @intToFloat(f32, raylib.GetScreenWidth());
	
	InitialBallPosition = .{ .x=(width/2), .y=(height/2)};
	ball.velocity 		= .{ .x=50, .y=25};
	ball.centerPosition = InitialBallPosition;
	ball.size 			= .{ .x=10, .y=10};
	player2.size = .{ .x=5, .y=50 };
	player1.size = .{ .x=5, .y=50 };
	player2.score = 0;
	player1.score = 0;
	player2.velocity = .{ .x=100, .y=100 };
	player1.velocity = .{ .x=100, .y=100 };
	player1.centerPosition = .{ .x=(0 + 5), .y=(height / 2)};
	player2.centerPosition = .{ .x=(width) - player2.size.x - 5, .y=(height / 2)};
	player1.input = .{
		.upButton	= raylib.KeyboardKey.KEY_W,
		.downButton	= raylib.KeyboardKey.KEY_S,
	};
	player2.input = .{
		.upButton	= raylib.KeyboardKey.KEY_I,
		.downButton	= raylib.KeyboardKey.KEY_K,
	};
	
    while (!raylib.WindowShouldClose()) { 
		var dt = raylib.GetFrameTime();
		try Update(dt);
		try Draw();
    }
}
	
pub fn Update(deltaTime:f32) !void {
	var height = @intToFloat(f32, raylib.GetScreenHeight());
	var width  = @intToFloat(f32, raylib.GetScreenWidth());
	{ // Update players
		for (players) |_, i| {
			var player = &players[i];
			if(raylib.IsKeyDown(player.input.downButton)){
				// Update position
				player.centerPosition.y += (deltaTime * player.velocity.y);
				// Clamp on bottom edge
				if(player.centerPosition.y + (player.size.y/2) > height){
					player.centerPosition.y = (height - (player.size.y / 2));
				}
			}
			if(raylib.IsKeyDown(player.input.upButton)){
				// Update position
				player.centerPosition.y -= (deltaTime * player.velocity.y);
				// Clamp on top edge
				if(player.centerPosition.y - (player.size.y/2) < 0){
					player.centerPosition.y = player.size.y / 2;                                                                                                                                                                                     
				}
			}
		}
	}
	{ // Update ball
		ball.centerPosition.x += deltaTime * ball.velocity.x;
		ball.centerPosition.y += deltaTime * ball.velocity.y;
	}
	{ // Check collisions
		for (players) |_, i| {
			var player = &players[i];
			var isDetectBallTouchesPad = DetectBallTouchesPad(&ball, player);
			if (isDetectBallTouchesPad) {
				ball.velocity.x *= -1;
			}
		}
		var isBallOnTopBottomScreenEdge = ball.centerPosition.y > (height) or ball.centerPosition.y < 0;
		var isBallOnRightScreenEdge = ball.centerPosition.x > (width);
		var isBallOnLeftScreenEdge = ball.centerPosition.x < 0;
		if (isBallOnTopBottomScreenEdge) {
			ball.velocity.y *= -1;
		}
		if (isBallOnLeftScreenEdge) {
			ball.centerPosition = InitialBallPosition;
			player2.score += 1;
		}
		if (isBallOnRightScreenEdge) {
			ball.centerPosition = InitialBallPosition;
			player1.score += 1;
		}
	}
}

pub fn Draw() !void {
	raylib.BeginDrawing();
	defer raylib.EndDrawing();
	raylib.ClearBackground(raylib.BLACK);
	
	var height = @intToFloat(f32, raylib.GetScreenHeight());
	var width  = @intToFloat(f32, raylib.GetScreenWidth());

	{ // Draw players
		for (players) |_, i| {
			var player = &players[i];
			raylib.DrawRectangle(@floatToInt(c_int, (player.centerPosition.x-(player.size.x/2))), 
								 @floatToInt(c_int, (player.centerPosition.y-(player.size.y/2))), 
								 @floatToInt(c_int, (player.size.x)), 
								 @floatToInt(c_int, (player.size.y)), 
								 raylib.WHITE);		
		}
	}
	{   // Draw Court Line
		const LineThinkness = 2.0;
		var x = width / 2.0;
		var from = raylib.Vector2 { .x = x, .y = 5 };
		var to = raylib.Vector2 { .x = x, .y = height - 5.0 };
		raylib.DrawLineEx(from, to, LineThinkness, raylib.LIGHTGRAY);
	}
	{ // Draw Scores
		DrawText(raylib.TextFormat("%d", player1.score), TextAlignment.Right, @floatToInt(c_int, width/2)-10, 10, 20);
		DrawText(raylib.TextFormat("%d", player2.score), TextAlignment.Left,  @floatToInt(c_int, width/2)+10, 10, 20);
	}
	{ // Draw Ball
		raylib.DrawRectangle(@floatToInt(c_int, (ball.centerPosition.x-(ball.size.x/2))), 
							 @floatToInt(c_int, (ball.centerPosition.y-(ball.size.y/2))), 
							 @floatToInt(c_int,(ball.size.x)), 
							 @floatToInt(c_int,(ball.size.y)), 
							 raylib.WHITE);
	}
}

pub fn DetectBallTouchesPad (b:*Ball, pad:*Pad) bool {
	if (b.centerPosition.x >= pad.centerPosition.x and b.centerPosition.x <= pad.centerPosition.x+pad.size.x) {
		if (b.centerPosition.y >= pad.centerPosition.y-(pad.size.y/2) and b.centerPosition.y <= pad.centerPosition.y+pad.size.y/2) {
			return true;
		}
	}
	return false;
}

pub fn DrawText(text:[*c]const u8, alignment:TextAlignment, posX:i32, posY:i32, fontSize :i32) void {
	var fontColor = raylib.LIGHTGRAY;
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