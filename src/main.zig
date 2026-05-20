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

    const file = std.Io.Dir.cwd().readFileAlloc(io, "oxi.glass", gpa, .unlimited) catch unreachable;
    defer gpa.free(file);

    const file_cstr = gpa.alloc(u8, file.len + 1) catch unreachable;
    defer gpa.free(file_cstr);

    std.mem.copyForwards(u8, file_cstr, file);
    file_cstr[file.len] = 0;

    const res = c.glass_parse(file_cstr.ptr);
    defer c.glass_result_free(res);

    if (c.glass_result_get_kind(res) == c.GLASS_RESULT_ERROR) {
        return error.InvalidGlassFile;
    }

    const value = c.glass_result_value(res);

    const cfg = try config.Config.parse(@ptrCast(&value[0]), gpa);
    defer cfg.free(gpa);

    std.debug.print("{s}\n", .{cfg.windows[1].cmd});
}
