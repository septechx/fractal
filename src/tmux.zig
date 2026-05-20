const std = @import("std");
const Io = std.Io;

pub fn create_session(io: Io, name: []const u8) !void {
    _ = try std.process.spawn(io, .{
        .argv = &[_][]const u8{
            "tmux",
            "new",
            "-s",
            name,
            "-d",
        },
    });
}
