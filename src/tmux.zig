const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;

pub fn attach(io: Io) !void {
    _ = try std.process.spawn(io, .{ .argv = &.{ "tmux", "attach" } });
}

pub fn createSession(io: Io, name: []const u8, path: []const u8) !void {
    _ = try std.process.spawn(io, .{ .argv = &.{ "tmux", "new", "-s", name, "-c", path, "-d" } });
}

pub fn createWindow(io: Io, gpa: Allocator, session: []const u8, index: u32, path: []const u8) !void {
    const window = try std.fmt.allocPrint(gpa, "{s}:{}", .{ session, index });
    defer gpa.free(window);
    _ = try std.process.spawn(io, .{ .argv = &.{ "tmux", "new-window", "-t", window, "-c", path } });
}

pub fn executeCommand(io: Io, gpa: Allocator, session: []const u8, index: u32, cmd: []const u8) !void {
    const window = try std.fmt.allocPrint(gpa, "{s}:{}", .{ session, index });
    defer gpa.free(window);
    _ = try std.process.spawn(io, .{ .argv = &.{ "tmux", "send-keys", "-t", window, cmd, "C-m" } });
}
