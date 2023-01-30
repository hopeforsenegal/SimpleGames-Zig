//
// build
// Zig version: 0.9.0
// Author: Nikolas Wipper
// Date: 2020-02-15
//

const std = @import("std");
const Builder = std.build.Builder;
const raylib = @import("lib.zig");

const Program = struct {
    name: []const u8,
    path: []const u8,
    desc: []const u8,
};

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});
    const examples_step = b.step("examples", "Builds all the examples");
    const system_lib = b.option(bool, "system-raylib", "link to preinstalled raylib libraries") orelse false;

	{
		const ex = .{
            .name = "sample",
            .path = "sample/sample.zig",
            .desc = "Creates a basic window with text",
        };
        const exe = b.addExecutable(ex.name, ex.path);

        exe.setBuildMode(mode);
        exe.setTarget(target);

        raylib.link(exe, system_lib);
        raylib.addAsPackage("raylib", exe);
        raylib.math.addAsPackage("raylib-math", exe);

        const run_cmd = exe.run();
        const run_step = b.step(ex.name, ex.desc);
        run_step.dependOn(&run_cmd.step);
        examples_step.dependOn(&exe.step);
	}
	{
		const ex = .{
            .name = "pong",
            .path = "pong/pong.zig",
            .desc = "Creates a basic window with text",
        };
        const exe = b.addExecutable(ex.name, ex.path);

        exe.setBuildMode(mode);
        exe.setTarget(target);

        raylib.link(exe, system_lib);
        raylib.addAsPackage("raylib", exe);
        raylib.math.addAsPackage("raylib-math", exe);

        const run_cmd = exe.run();
        const run_step = b.step(ex.name, ex.desc);
        run_step.dependOn(&run_cmd.step);
        examples_step.dependOn(&exe.step);
	}
	{
		const ex = .{
            .name = "breakout",
            .path = "breakout/breakout.zig",
            .desc = "Creates a basic window with text",
        };
        const exe = b.addExecutable(ex.name, ex.path);

        exe.setBuildMode(mode);
        exe.setTarget(target);

        raylib.link(exe, system_lib);
        raylib.addAsPackage("raylib", exe);
        raylib.math.addAsPackage("raylib-math", exe);

        const run_cmd = exe.run();
        const run_step = b.step(ex.name, ex.desc);
        run_step.dependOn(&run_cmd.step);
        examples_step.dependOn(&exe.step);
	}
	{
		const ex = .{
            .name = "space_invaders",
            .path = "space invaders/space invaders.zig",
            .desc = "Creates a basic window with text",
        };
        const exe = b.addExecutable(ex.name, ex.path);

        exe.setBuildMode(mode);
        exe.setTarget(target);

        raylib.link(exe, system_lib);
        raylib.addAsPackage("raylib", exe);
        raylib.math.addAsPackage("raylib-math", exe);

        const run_cmd = exe.run();
        const run_step = b.step(ex.name, ex.desc);
        run_step.dependOn(&run_cmd.step);
        examples_step.dependOn(&exe.step);
	}
}
