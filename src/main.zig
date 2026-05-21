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

    const cfg = try getGlobalConfig(io, gpa, environ_map);

    // TODO: Get this as argument
    const name = "testing";

    const file_name = try std.fmt.allocPrint(gpa, "{s}.glass", .{name});
    defer gpa.free(file_name);

    const file = try std.Io.Dir.cwd().readFileAlloc(io, file_name, gpa, .unlimited);
    defer gpa.free(file);

    const file_cstr = try toCstrSlice(gpa, file);
    defer gpa.free(file_cstr);

    const res = c.glass_parse(file_cstr.ptr);
    defer c.glass_result_free(res);

    if (c.glass_result_get_kind(res) == c.GLASS_RESULT_ERROR)
        return error.InvalidGlassFile;

    const value = c.glass_result_value(res);

    const layout = try config.Layout.parse(@ptrCast(&value[0]), environ_map, gpa);
    defer layout.free(gpa);

    try processLayout(io, gpa, cfg, name, layout);
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
}

fn getGlobalConfig(io: Io, gpa: Allocator, environ_map: *const std.process.Environ.Map) !config.Config {
    const config_path = try getConfigPath(gpa, environ_map);
    defer gpa.free(config_path);

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

fn getConfigPath(gpa: Allocator, environ_map: *const std.process.Environ.Map) ![]const u8 {
    if (environ_map.get("FRACTAL_CONFIG_OVERRIDE")) |override| return gpa.dupe(u8, override);

    return try std.fmt.allocPrint(gpa, "{s}/.config/fractal/config.glass", .{
        environ_map.get("HOME") orelse @panic("$HOME is not set"),
    });
}
