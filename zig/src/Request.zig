const std = @import("std");
const net = std.net;
const http = @import("http.zig");
const Request = @This();
const KV = @import("routes.zig").KV;

method: Method,
uri: []const u8,
version: Version,
headers: std.StringHashMap([]const u8),
query_params: ?std.StringHashMap([]const u8),
path_params: ?[]const KV,
reader: net.Stream.Reader,

pub const ParsingError = error{
    MethodNotValid,
    VersionNotValid,
};

pub const Method = enum {
    GET,
    DELETE,
    OPTION,
    PATCH,
    POST,
    PUT,
    pub fn fromString(s: []const u8) !Method {
        var method = std.meta.stringToEnum(Method, s);
        if (method) |m| {
            return m;
        } else {
            return ParsingError.MethodNotValid;
        }
    }
};

pub const Version = enum {
    @"HTTP/1.1",
    @"HTTP/2",
    pub fn fromString(s: []const u8) !Version {
        var version = std.meta.stringToEnum(Version, s);
        if (version) |v| {
            return v;
        } else {
            return ParsingError.VersionNotValid;
        }
    }
    pub fn toString(self: Version) []const u8 {
        var version = switch (self) {
            .@"HTTP/1.1" => "HTTP/1.1",
            .@"HTTP/2" => "HTTP/2"
        };
        return version;
    }
};

pub fn debugPrintRequest(self: *Request) void {
    std.debug.print("method: {s}\nuri: {s}\nversion:{s}\n", .{ self.method, self.uri, self.version });
    var headers_iter = self.headers.iterator();
    if (self.query_params) |_| {
        var query_params_iter = self.query_params.?.iterator();
        std.debug.print("query params:\n", .{});
        while (query_params_iter.next()) |entry| {
            std.debug.print("{s}: {s}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
        }
    }
    std.debug.print("headers:\n", .{});
    while (headers_iter.next()) |entry| {
        std.debug.print("{s}: {s}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
    }
}

pub fn init(allocator: std.mem.Allocator, reader: net.Stream.Reader) !Request {
    var first_line = try reader.readUntilDelimiterAlloc(allocator, '\n', std.math.maxInt(usize));
    first_line = first_line[0 .. first_line.len - 1];
    var first_line_iter = std.mem.split(u8, first_line, " ");

    const method = first_line_iter.next().?;

    // Seperating uri from query params part and parsing query params into a hashmap
    var uri = first_line_iter.next().?;

    var start_of_query_params = std.mem.indexOf(u8, uri, "?");
    var query_params: ?std.StringHashMap([]const u8) = null;
    if (start_of_query_params) |_| {
        start_of_query_params = start_of_query_params.? + 1;
        query_params = std.StringHashMap([]const u8).init(allocator);
        const query_params_str = uri[start_of_query_params.?..];
        uri = uri[0 .. start_of_query_params.? - 1];
        var query_params_iter = std.mem.split(u8, query_params_str, "&");
        query_params = std.StringHashMap([]const u8).init(allocator);
        while (query_params_iter.next()) |query_param| {
            var query_param_iter = std.mem.split(u8, query_param, "=");
            const key = query_param_iter.next().?;
            const value = query_param_iter.next().?;
            try query_params.?.put(key, value);
        }
    }

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
        .query_params = query_params,
        .path_params = null,
        .uri = uri,
        .reader = reader,
    };
}

pub fn getParam(self: *Request, name: []const u8) ?[]const u8 {
    const eql = std.mem.eql;
    if (self.path_params) |kvs| {
        for (kvs) |kv| {
            if (eql(u8, kv.name, name)) {
                return kv.value;
            }
        }
    }

    return null;
}

pub fn getQueryParam(self: *Request, name: []const u8) ?[]const u8 {
    return self.query_params.?.get(name).?;
}
