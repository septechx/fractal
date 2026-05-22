const std = @import("std");
const assert = std.debug.assert;
const Io = std.Io;
const Allocator = std.mem.Allocator;
const tmux = @import("tmux.zig");
const config = @import("config.zig");
const c = @cImport({
    @cInclude("glass.h");
});

fn toCstrSlice(gpa: Allocator, str: []const u8) ![]const u8 {
    const cstr = try gpa.alloc(u8, str.len + 1);
    std.mem.copyForwards(u8, cstr, str);
    cstr[str.len] = 0;
    return cstr;
}

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    const io = init.io;
    const environ_map = init.environ_map;

    const args = try init.minimal.args.toSlice(gpa);
    defer gpa.free(args);
    if (args.len < 2) return error.NotEnoughArguments;
    const target_layout = args[1];

    const cfg = try getGlobalConfig(io, gpa, environ_map);

    const layout = try getLayout(io, gpa, environ_map, target_layout);
    defer layout.free(gpa);

    try processLayout(io, gpa, cfg, target_layout, layout);
}

fn processLayout(io: Io, gpa: Allocator, cfg: config.Config, name: []const u8, layout: config.Layout) !void {
    try tmux.createSession(io, name, layout.dir);

    for (layout.windows, 0..) |window, i| {
        const cmd = window.cmd;
        const index: u32 = @truncate(i + cfg.first_window_offset);
        if (index > 1) try tmux.createWindow(io, gpa, name, index, layout.dir);
        if (cmd.len != 0)
            try tmux.executeCommand(io, gpa, name, index, layout.windows[i].cmd);
    }

    try tmux.attach(io);
}

fn getLayout(io: Io, gpa: Allocator, environ_map: *const std.process.Environ.Map, target: []const u8) !config.Layout {
    const layout_path = try getConfigPath(gpa, environ_map, target);
    defer gpa.free(layout_path);

    _ = std.Io.Dir.cwd().statFile(io, layout_path, .{}) catch return error.LayoutNotFound;

    const layout_str = try std.Io.Dir.cwd().readFileAlloc(io, layout_path, gpa, .unlimited);
    defer gpa.free(layout_str);

    const layout_cstr = try toCstrSlice(gpa, layout_str);
    defer gpa.free(layout_cstr);

    const res = c.glass_parse(layout_cstr.ptr);
    defer c.glass_result_free(res);

    if (c.glass_result_get_kind(res) == c.GLASS_RESULT_ERROR)
        return error.InvalidGlassFile;

    const value = c.glass_result_value(res);
    return try config.Layout.parse(@ptrCast(&value[0]), environ_map, gpa);
}

fn getGlobalConfig(io: Io, gpa: Allocator, environ_map: *const std.process.Environ.Map) !config.Config {
    const config_path = try getConfigPath(gpa, environ_map, "config");
    defer gpa.free(config_path);

    _ = std.Io.Dir.cwd().statFile(io, config_path, .{}) catch {
        const dirname = std.fs.path.dirname(config_path) orelse ".";
        try std.Io.Dir.cwd().createDirPath(io, dirname);
        var config_file = try std.Io.Dir.cwd().createFile(io, config_path, .{});
        defer config_file.close(io);
        try config_file.writeStreamingAll(io, "root {\n    first_window_offset 0,\n},\n");
    };

    const config_str = try std.Io.Dir.cwd().readFileAlloc(io, config_path, gpa, .unlimited);
    defer gpa.free(config_str);

    const config_cstr = try toCstrSlice(gpa, config_str);
    defer gpa.free(config_cstr);

    const res = c.glass_parse(config_cstr.ptr);
    defer c.glass_result_free(res);

    if (c.glass_result_get_kind(res) == c.GLASS_RESULT_ERROR)
        return error.InvalidGlassFile;

    const value = c.glass_result_value(res);
    return config.Config.parse(@ptrCast(&value[0]));
}

fn getConfigPath(gpa: Allocator, environ_map: *const std.process.Environ.Map, target: []const u8) ![]const u8 {
    if (environ_map.get("FRACTAL_CONFIG_OVERRIDE")) |override| return try std.fmt.allocPrint(gpa, "{s}/{s}.glass", .{ override, target });

    return try std.fmt.allocPrint(gpa, "{s}/.config/fractal/{s}.glass", .{
        environ_map.get("HOME") orelse @panic("$HOME is not set"),
        target,
    });
}
