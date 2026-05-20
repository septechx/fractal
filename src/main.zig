const std = @import("std");
const assert = std.debug.assert;
const Io = std.Io;
const Allocator = std.mem.Allocator;
const tmux = @import("tmux.zig");
const config = @import("config.zig");
const c = @cImport({
    @cInclude("glass.h");
});

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    const io = init.io;

    // TODO: Get this as argument
    const name = "testing";

    const file_name = try std.fmt.allocPrint(gpa, "{s}.glass", .{name});
    defer gpa.free(file_name);

    const file = std.Io.Dir.cwd().readFileAlloc(io, file_name, gpa, .unlimited) catch unreachable;
    defer gpa.free(file);

    const file_cstr = gpa.alloc(u8, file.len + 1) catch unreachable;
    defer gpa.free(file_cstr);

    std.mem.copyForwards(u8, file_cstr, file);
    file_cstr[file.len] = 0;

    const res = c.glass_parse(file_cstr.ptr);
    defer c.glass_result_free(res);

    if (c.glass_result_get_kind(res) == c.GLASS_RESULT_ERROR)
        return error.InvalidGlassFile;

    const value = c.glass_result_value(res);

    const cfg = try config.Config.parse(@ptrCast(&value[0]), init.environ_map, gpa);
    defer cfg.free(gpa);

    try process_cfg(io, gpa, name, cfg);
}

fn process_cfg(io: Io, gpa: Allocator, name: []const u8, cfg: config.Config) !void {
    try tmux.create_session(io, name, cfg.dir);

    for (0..cfg.windows.len) |i| {
        const cmd = cfg.windows[i].cmd;
        const index: u32 = @truncate(i + 1);
        if (index > 1) try tmux.create_window(io, gpa, name, index, cfg.dir);
        if (cmd.len != 0)
            try tmux.execute_command(io, gpa, name, index, cfg.windows[i].cmd);
    }
}
