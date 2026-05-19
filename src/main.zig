const std = @import("std");
const assert = std.debug.assert;
const Io = std.Io;
const Allocator = std.mem.Allocator;
const c = @cImport({
    @cInclude("glass.h");
});

pub fn main() !void {
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    defer assert(debug_allocator.deinit() == .ok);
    const gpa = debug_allocator.allocator();

    var threaded: std.Io.Threaded = .init(gpa, .{});
    defer threaded.deinit();
    const io = threaded.io();

    const file = std.Io.Dir.cwd().readFileAlloc(io, "oxi.glass", gpa, .unlimited) catch unreachable;
    defer gpa.free(file);

    const file_cstr = gpa.alloc(u8, file.len + 1) catch unreachable;
    defer gpa.free(file_cstr);

    std.mem.copyForwards(u8, file_cstr, file);
    file_cstr[file_cstr.len - 1] = 0;

    const res = c.glass_parse(file_cstr.ptr);
    defer c.glass_result_free(res);

    std.debug.print("result = {*}; kind = {}\n", .{ res, c.glass_result_get_kind(res) });
}
