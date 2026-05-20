const std = @import("std");
const Allocator = std.mem.Allocator;
const c = @cImport({
    @cInclude("glass.h");
});

pub const Config = struct {
    dir: []const u8,
    windows: []Window,

    pub fn parse(value: *const c.GlassValue, environ_map: *const std.process.Environ.Map, gpa: Allocator) !Config {
        const map = c.glass_value_get_map(value);
        const len = c.glass_map_len(map);

        var windows_value: ?*const c.GlassValue = null;
        var dir_value: ?*const c.GlassValue = null;
        for (0..len) |i| {
            const entry = c.glass_map_get(map, i);
            const key = std.mem.sliceTo(c.glass_map_entry_key(entry), 0);
            if (std.mem.eql(u8, key, "windows")) {
                windows_value = c.glass_map_entry_value(entry);
            } else if (std.mem.eql(u8, key, "dir")) {
                dir_value = c.glass_map_entry_value(entry);
            }
        }

        const dir_str = std.mem.sliceTo(c.glass_value_get_string(dir_value.?), 0);
        const dir = if (std.mem.startsWith(u8, dir_str, "~/"))
            try std.fmt.allocPrint(gpa, "{s}{s}", .{
                environ_map.get("HOME") orelse @panic("$HOME is not set"),
                dir_str[1..],
            })
        else
            try gpa.dupe(u8, dir_str);

        const arr = c.glass_value_get_array(windows_value.?);
        const arr_len = c.glass_array_len(arr);
        const windows = try gpa.alloc(Window, arr_len);

        for (0..arr_len) |i| {
            const window_value = c.glass_array_get(arr, i);
            const window_map = c.glass_value_get_map(window_value);
            const wlen = c.glass_map_len(window_map);

            var cmd_str: [*c]const u8 = undefined;
            for (0..wlen) |j| {
                const entry = c.glass_map_get(window_map, j);
                const key = std.mem.sliceTo(c.glass_map_entry_key(entry), 0);
                if (std.mem.eql(u8, key, "cmd")) {
                    cmd_str = c.glass_value_get_string(c.glass_map_entry_value(entry));
                }
            }

            const cmd_len = std.mem.len(cmd_str);
            const cmd = try gpa.alloc(u8, cmd_len);
            @memcpy(cmd, cmd_str[0..cmd_len]);
            windows[i] = .{ .cmd = cmd };
        }

        return .{ .windows = windows, .dir = dir };
    }

    pub fn free(self: Config, gpa: Allocator) void {
        for (0..self.windows.len) |i| {
            gpa.free(self.windows[i].cmd);
        }
        gpa.free(self.windows);
        gpa.free(self.dir);
    }
};

pub const Window = struct {
    cmd: []const u8,
};
