const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;

pub fn create_session(io: Io, name: []const u8) !void {
    _ = try std.process.spawn(io, .{ .argv = &.{
        "tmux",
        "new",
        "-s",
        name,
        "-d",
    } });
}

pub fn create_window(io: Io, gpa: Allocator, session: []const u8, index: u32) !void {
    const window = try std.fmt.allocPrint(gpa, "{s}:{}", .{ session, index });
    defer gpa.free(window);
    _ = try std.process.spawn(io, .{ .argv = &.{
        "tmux",
        "new-window",
        "-t",
        window,
    } });
}

pub fn execute_command(io: Io, gpa: Allocator, session: []const u8, index: u32, cmd: []const u8) !void {
    const window = try std.fmt.allocPrint(gpa, "{s}:{}", .{ session, index });
    defer gpa.free(window);
    _ = try std.process.spawn(io, .{ .argv = &.{
        "tmux",
        "send-keys",
        "-t",
        window,
        cmd,
        "C-m",
    } });
}
