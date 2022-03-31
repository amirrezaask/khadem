const std = @import("std");
const net = std.net;
const http = @import("http.zig");
const Request = @This();

method: Method,
uri: []const u8,
version: Version,
headers: std.StringHashMap([]const u8),
reader: net.Stream.Reader,

pub const ParsingError = error{
    MethodNotValid,
    VersionNotValid,
};

pub const Method = enum {
    GET,
    POST,
    PUT,
    PATCH,
    OPTION,
    DELETE,
    pub fn fromString(s: []const u8) !Method {
        if (std.mem.eql(u8, "GET", s)) return .GET;
        if (std.mem.eql(u8, "POST", s)) return .POST;
        if (std.mem.eql(u8, "PUT", s)) return .PUT;
        if (std.mem.eql(u8, "PATCH", s)) return .PATCH;
        if (std.mem.eql(u8, "OPTION", s)) return .OPTION;
        if (std.mem.eql(u8, "DELETE", s)) return .DELETE;
        return ParsingError.MethodNotValid;
    }
};

pub const Version = enum {
    @"1.1",
    @"2",

    pub fn fromString(s: []const u8) !Version {
        if (std.mem.eql(u8, "HTTP/1.1", s)) return .@"1.1";
        if (std.mem.eql(u8, "HTTP/2", s)) return .@"2";
        return ParsingError.VersionNotValid;
    }

    pub fn asString(self: Version) []const u8 {
        if (self == Version.@"1.1") return "HTTP/1.1";
        if (self == Version.@"2") return "HTTP/2";
        unreachable;
    }
};

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
