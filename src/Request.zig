const std = @import("std");
const net = std.net;
const http = @import("http.zig");
const Method = http.Method;
const Version = http.Version;
const Request = @This();

method: Method,
uri: []const u8,
version: Version,
headers: std.StringHashMap([]const u8),
reader: net.Stream.Reader,

pub fn debugPrintRequest(self: *Request) void {
    std.debug.print("method: {s}\nuri: {s}\nversion:{s}\n", .{ self.method, self.uri, self.version });
    var headers_iter = self.headers.iterator();
    while (headers_iter.next()) |entry| {
        std.debug.print("{s}: {s}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
    }
}

pub fn init(allocator: std.mem.Allocator, reader: net.Stream.Reader) !Request {
    var first_line = try reader.readUntilDelimiterAlloc(allocator, '\n', std.math.maxInt(usize));
    first_line = first_line[0 .. first_line.len - 1];
    var first_line_iter = std.mem.split(u8, first_line, " ");

    const method = first_line_iter.next().?;
    const uri = first_line_iter.next().?;
    const version = first_line_iter.next().?;
    var headers = std.StringHashMap([]const u8).init(allocator);

    while (true) {
        var line = try reader.readUntilDelimiterAlloc(allocator, '\n', std.math.maxInt(usize));
        if (line.len == 1 and std.mem.eql(u8, line, "\r")) break;
        line = line[0..line.len];
        var line_iter = std.mem.split(u8, line, ":");
        const key = line_iter.next().?;
        var value = line_iter.next().?;
        if (value[0] == ' ') value = value[1..];
        try headers.put(key, value);
    }
    return Request{
        .headers = headers,
        .method = try Method.fromString(method),
        .version = try Version.fromString(version),
        .uri = uri,
        .reader = reader,
    };
}
