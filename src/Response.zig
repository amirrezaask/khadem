const Response = @This();
const std = @import("std");
const net = std.net;
const http = @import("http.zig");
const Method = http.Method;
const Version = http.Method;
const Request = @This();

writer: net.Stream.Writer,
version: http.Version,

pub fn respond(self: *Response, status: http.Status, maybe_headers: ?std.StringHashMap([]const u8), body: []const u8) !void {
    try self.writer.print("{s} {} {s}\r\n", .{ self.version.asString(), status.code, status.message });
    if (maybe_headers) |headers| {
        var headers_iter = headers.iterator();
        while (headers_iter.next()) |entry| {
            try self.writer.print("{s}: {s}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
        }
    }
    try self.writer.print("\r\n", .{});

    _ = try self.writer.write(body);
}
