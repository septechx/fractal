const std = @import("std");
const c = @cImport({
    @cInclude("glass.h");
});

fn printIndent(indent: usize) void {
    var i: usize = 0;
    while (i < indent) {
        std.debug.print("  ", .{});
        i += 1;
    }
}

fn printValue(value: *const c.GlassValue, indent: usize) void {
    switch (c.glass_value_get_kind(value)) {
        c.GLASS_NULL => std.debug.print("null", .{}),
        c.GLASS_BOOL => std.debug.print("{s}", .{if (c.glass_value_get_bool(value)) "true" else "false"}),
        c.GLASS_NUMBER => std.debug.print("{d}", .{c.glass_value_get_number(value)}),
        c.GLASS_STRING => std.debug.print("\"{s}\"", .{c.glass_value_get_string(value)}),
        c.GLASS_ARRAY => {
            const arr = c.glass_value_get_array(value);
            std.debug.print("[\n", .{});
            const len = c.glass_array_len(arr);
            var i: usize = 0;
            while (i < len) {
                printIndent(indent + 1);
                printValue(c.glass_array_get(arr, i), indent + 1);
                i += 1;
                if (i < len) std.debug.print(",", .{});
                std.debug.print("\n", .{});
            }
            printIndent(indent);
            std.debug.print("]", .{});
        },
        c.GLASS_MAP => {
            const map = c.glass_value_get_map(value);
            std.debug.print("{{\n", .{});
            const len = c.glass_map_len(map);
            var i: usize = 0;
            while (i < len) {
                const entry = c.glass_map_get(map, i);
                printIndent(indent + 1);
                std.debug.print("\"{s}\" ", .{c.glass_map_entry_key(entry)});
                printValue(c.glass_map_entry_value(entry), indent + 1);
                i += 1;
                if (i < len) std.debug.print(",", .{});
                std.debug.print("\n", .{});
            }
            printIndent(indent);
            std.debug.print("}}", .{});
        },
        else => {},
    }
}
