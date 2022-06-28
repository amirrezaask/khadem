const Response = @This();
const std = @import("std");
const net = std.net;
const http = @import("http.zig");
const Request = http.Request;

writer: net.Stream.Writer,
version: Request.Version,

pub fn respond(self: *Response, payload: Payload) !void {
    try self.writer.print("{s} {} {s}\r\n", .{ self.version.toString(), payload.status.code(), payload.status.toString() });
    if (payload.headers) |headers| {
        var headers_iter = headers.iterator();
        while (headers_iter.next()) |entry| {
            try self.writer.print("{s}: {s}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
        }
    }
    try self.writer.print("\r\n", .{});

    _ = try self.writer.write(payload.body);
}

pub const Status = enum(usize) {
    Ok = 200,
    Created = 201,
    Accepted = 202,
    NoContent = 204,
    NotFound = 404,
    BadRequest = 400,
    Forbidden = 403,
    UnAuthorized = 401,

    pub fn code(self: Status) usize {
        var status = @enumToInt(self);
        return status;
    }

    pub fn toString(self: Status) []const u8 {
        var status = @tagName(self);
        return status;
    }
};

pub const Payload = struct {
    status: Status,
    body: []const u8,
    headers: ?std.StringHashMap([]const u8) = undefined,
};
