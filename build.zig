const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const glass = b.addSystemCommand(&.{ "cargo", "-Z", "unstable-options", "-C", "glass", "build", "--features", "capi" });
    if (optimize == .Debug) {
        glass.setEnvironmentVariable("RUSTFLAGS", "-g");
    } else {
        glass.addArg("--release");
    }

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe_mod.addIncludePath(b.path("glass/include/"));
    exe_mod.addLibraryPath(b.path(if (optimize == .Debug) "glass/target/debug/" else "glass/target/release/"));
    exe_mod.linkSystemLibrary("glass", .{});

    const exe = b.addExecutable(.{
        .name = "fractal",
        .root_module = exe_mod,
        .linkage = .dynamic,
    });

    exe.step.dependOn(&glass.step);

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });
    const run_exe_tests = b.addRunArtifact(exe_tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_exe_tests.step);
}
